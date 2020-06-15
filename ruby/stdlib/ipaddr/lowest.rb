require 'ipaddr'

class IPAddr
  def lowest
    low = self.dup
    low.prefix = 32
    low
  end
end

if __FILE__ == $PROGRAM_NAME
  puts IPAddr.new(ARGV.first).lowest
end
