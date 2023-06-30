require 'socket'
require 'ipaddr'

TIMEOUT = 10

def io_copy(from, to)
  loop do
    IO.select([from])
    to.sendmsg(from.recvfrom_nonblock(100_000).first)
  end
rescue IOError, Errno::EPIPE
  from.close_read rescue nil
  from.close_write rescue nil
  to.close_read rescue nil
  to.close_write rescue nil
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
    resp[:domain] = socket.gets("\0").chomp("\0")
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
    remote = Socket.tcp(connect_to[:domain] || connect_to[:ip], connect_to[:port], connect_timeout: TIMEOUT)
    puts "connected"
    # tell the client we connected
    client.sendmsg("\x00\x5A\xbe\x23\x7f\x00\x00\x01")
    Thread.new{io_copy(client, remote)}
    Thread.new{io_copy(remote, client)}
    puts "copy threads started"
  end
end
