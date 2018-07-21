class IPAddr
  def highest
    high = self.to_range.last
    high.prefix = 32
    high
  end
end
