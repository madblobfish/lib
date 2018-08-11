class IPAddr
  def include_block?(other)
    self.to_range.first <= other.to_range.first &&
    self.to_range.last  >= other.to_range.last
  end
end
