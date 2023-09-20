require 'ipaddr'

class IPAddr
  def size
    if self.ipv4?
      2**((4*8)-self.prefix)
    elsif self.ipv6?
      2**((16*8)-self.prefix)
    else
      raise ArgumentError, "bla"
    end
  end
  alias :count :size
end
