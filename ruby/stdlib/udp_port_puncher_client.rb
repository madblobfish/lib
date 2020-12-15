require 'socket'

unless identifier = ARGV.first
  require 'securerandom'
  identifier = SecureRandom.hex(12)
  STDERR.puts "Your identifier is: #{identifier}"
end

s = Socket.new(:INET, :DGRAM)
s.connect(Socket.pack_sockaddr_in(1235, '192.168.178.33'))
s.write(identifier)
raise "no response" if IO.select([s], [], [], 5) == nil

t, ip, port = s.recvfrom(99)[0].split("\t")
if t == "first"
  raise "timeout for other" if IO.select([s], [], [], 60) == nil
  ip, port = s.recvfrom(99)[0].split("\t")
  p ip, port
else
  p t, ip, port

  raise "too late" unless (-1..60).include?(Time.now - Time.at(t.to_i(10)))
end
STDERR.puts
# s.close() # tcp only
# s = Socket.new(:INET, :DGRAM)
s.connect(Socket.pack_sockaddr_in(port.to_i, ip))
STDERR.puts(s.write_nonblock(identifier))
s.connect(Socket.pack_sockaddr_in(port.to_i, ip))
STDERR.puts(s.write_nonblock(identifier))
sleep(0.1)
# s.write_nonblock(identifier)
if IO.select([s], [], [], 1) == nil
  STDERR.puts "no response"
  s.write(identifier)
  raise "ahh" if IO.select([s], [], [], 1) == nil
end
raise "ahh" if IO.select([s], [], [], 1) == nil
STDERR.puts(s.recvfrom(99).inspect)
