class IPAddr
  require_relative 'highest'
  def next_to?(other)
    other.include?(self.highest.succ) || self.include?(other.highest.succ)
  end
end
