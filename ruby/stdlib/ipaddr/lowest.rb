class IPAddr
  def lowest
    high = self.to_range.first
    high.prefix = 32
    high
  end
end
