require 'socket'
require 'ipaddr'
require 'open3'
require 'uri'
require 'shellwords'

TIMEOUT = 10

raise 'give me one argument, the server to use as a proxy' unless ARGV.one?

def io_copy(from, to)
  loop do
    IO.select([from])
    to.sendmsg(from.read_nonblock(100_000))
  end
rescue IOError, Errno::EPIPE
  from.close_read rescue nil
  from.close_write rescue nil
  to.close_read rescue nil
  to.close_write rescue nil
  puts 'killed connection'
end

def socks4_parse(socket)
  raise 'wrong protocol & cmd' unless socket.read(2) == "\04\01"
  port = socket.read(2).unpack1('s>')
  ip_bytes = socket.read(4)
  ip = IPAddr.new_ntoh(ip_bytes)
  client_id = socket.gets("\0").chomp("\0")
  resp = {ip: ip, port: port, client_id: client_id}
  if ip_bytes.start_with?("\0\0\0") && ip_bytes != "\0\0\0\0"
    # socks4a
    resp[:domain] = URI('http://' + socket.gets("\0").chomp("\0")).hostname
  end
  return resp
end

puts "starting loop"
Socket.tcp_server_loop(9150) do |client, client_addrinfo|
  puts "got new connection"
  Thread.new do
    # client.timeout = TIMEOUT
    connect_to = socks4_parse(client)
    puts "connecting to: #{connect_to[:domain] || connect_to[:ip]} @#{connect_to[:port]}"
    # remote = Socket.tcp(connect_to[:domain] || connect_to[:ip], connect_to[:port], connect_timeout: TIMEOUT)
    remote_cmd = "ssh #{Shellwords.escape(ARGV.first)} nc #{Shellwords.escape(connect_to[:domain] || connect_to[:ip])} #{connect_to[:port]}"
    puts "executing: #{remote_cmd}"
    remote_stdin, remote_stdout, wait_thread = Open3.popen2(remote_cmd)
    def remote_stdin.sendmsg(str)
      self.write(str)
    end
    def client.read_nonblock(bytes)
      self.recvfrom_nonblock(bytes).first
    end
    puts "connected"
    # tell the client we connected
    client.sendmsg("\x00\x5A\xbe\x23\x7f\x00\x00\x01")
    Thread.new{io_copy(client, remote_stdin)}
    Thread.new{io_copy(remote_stdout, client)}
    puts "copy threads started"
  end
end
