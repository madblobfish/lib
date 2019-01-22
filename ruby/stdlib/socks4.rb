# this one takes ipv4
def socks4(ip, port, socks_ip: '127.0.0.1', socks_port: 9150)
  require 'socket'
  require 'ipaddr'

  s = TCPSocket.new(socks_ip, socks_port)
  ip = IPAddr.new(ip) unless ip.is_a?(IPAddr)
  s.puts("\04\01#{[port].pack("s").reverse}#{ip.hton}a\0".b)
  raise "Ahh!" if s.read(8)[1] != "Z"
  s
end

# this one takes dns names
def socks4a(name, port, socks_ip: '127.0.0.1', socks_port: 9150)
  require 'socket'

  s = TCPSocket.new(socks_ip, socks_port)
  s.puts("\04\01#{[port].pack("s").reverse}\00\00\00\1a\0#{name}\0".b)
  raise "Ahh!" if s.read(8)[1] != "Z"
  s
end

# this takes ipv4 as well as dns names
def socks4_abstraction(thing, port, socks_ip: '127.0.0.1', socks_port: 9150)
  require 'ipaddr'
  thing = IPAddr.new(thing) rescue thing
  return socks4(thing, port, socks_ip, socks_port) if thing.is_a?(IPAddr)
  socks4a(thing, port, socks_ip, socks_port)
end

# this takes ipv4 as well as dns names
# basicly same as above but merged implementations
def socks4_and_socks4a(thing, port, socks_ip: '127.0.0.1', socks_port: 9150)
  require 'socket'
  require 'ipaddr'

  thing = IPAddr.new(thing) rescue thing
  s = TCPSocket.new(socks_ip, socks_port)
  if thing.is_a?(IPAddr)
    s.puts("\04\01#{[port].pack("s").reverse}#{thing.hton}a\0".b)
  else
    s.puts("\04\01#{[port].pack("s").reverse}\00\00\00\1a\0#{thing}\0".b)
  end
  raise "Ahh!" if s.read(8)[1] != "Z"
  s
end


## example with ipecho.net
# s = socks4a("ipecho.net", 80);
# s.puts("GET /plain HTTP/1.1\r\nConnection: close\r\nHost: ipecho.net\r\nAccept: */*\r\nUser-Agent: curl\r\n\r\n")
# puts(s.read.gsub(/(?:.|\s)+\r\n\r\n(.+)/, '\1'))
# s.close

## ssl example with ipecho.net
# require 'openssl'
# bla = socks4a("ipecho.net", 443)
# s = OpenSSL::SSL::SSLSocket.new(bla)
# s.puts("GET /plain HTTP/1.1\r\nConnection: close\r\nHost: ipecho.net\r\nAccept: */*\r\nUser-Agent: curl/7.63.0\r\n\r\n")
# s.read
# puts(s.read.gsub(/(?:.|\s)+\r\n\r\n(.+)/, '\1'))
# s.close
# bla.close
