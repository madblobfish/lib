require 'ipaddr'

class IPAddr
  def include_block?(other)
    raise ArgumentError, "other is not a IPAddr" unless other.is_a?(IPAddr)
    self.to_range.first <= other.to_range.first &&
    self.to_range.last  >= other.to_range.last
  end
end

if __FILE__ == $PROGRAM_NAME
	puts IPAddr.new(ARGV.first).include_block?(IPAddr.new(ARGV[1]))
end
