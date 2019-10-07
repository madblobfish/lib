class IPAddr
  def include_block?(other)
    raise ArgumentError, "other is not a IPAddr" unless other.is_a?(IPAddr)
    self.to_range.first <= other.to_range.first &&
    self.to_range.last  >= other.to_range.last
  end
end
