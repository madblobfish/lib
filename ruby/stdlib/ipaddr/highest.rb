require 'ipaddr'

class IPAddr
  def highest
    high = self.to_range.last
    high.prefix = 32
    high
  end
end

if __FILE__ == $PROGRAM_NAME
  puts IPAddr.new(ARGV.first).highest
end
