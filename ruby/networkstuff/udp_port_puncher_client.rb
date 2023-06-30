require 'socket'

##
# todo:
#   * implement unix socket output instead of stdin/out
#   * implement keepalive (how to filter keepalive out? maybe need to encode packages or prepend a single bit)
#   * implement recovery from port closing down (new punchthrough)
#   * implement better start procedure in case of errors? (maybe needs to be fixed?)

unless identifier = ARGV.first
  require 'securerandom'
  identifier = SecureRandom.hex(12)
  STDERR.print('Your identifier is: ')
  STDERR.puts(identifier)
end

s = Socket.new(:INET, :DGRAM)
s.connect(Socket.pack_sockaddr_in(1235, '192.168.178.33'))
s.write(identifier)
raise 'no response' if IO.select([s], [], [], 5) == nil

t, ip, port = s.recvfrom(99)[0].split("\t")
first = false
if t == 'first'
  raise 'timeout for other' if IO.select([s], [], [], 60) == nil
  ip, port = s.recvfrom(30)[0].split("\t")
  # p ip, port
  first = true
else
  # p t, ip, port

  raise 'too late' unless (-1..60).include?(Time.now - Time.at(t.to_i(10)))
end
# STDERR.puts
# s.close() # tcp only
# s = Socket.new(:INET, :DGRAM)
s.connect(Socket.pack_sockaddr_in(port.to_i, ip))
s.write_nonblock(identifier + first.to_s)
# s.write_nonblock(identifier)
if IO.select([s], [], [], 1) == nil
  STDERR.puts 'no response'
  s.write(identifier + first.to_s)
  raise 'AHH' if IO.select([s], [], [], 1) == nil
end
raise 'strange' unless s.read_nonblock(100) == "#{identifier}#{!first}"

def io_copy(from, to)
  loop do
    IO.select([from])
    to.write(from.read_nonblock(100_000))
  end
end

Thread.new{io_copy(STDIN, s)}
io_copy(s, STDOUT)
