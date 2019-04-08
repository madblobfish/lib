class CSV
  # returns the CSV as an array of Hashes, if headers are defined.
  def to_h
    raise ArgumentError, "headers are needed for this operation" unless headers
    self.map(&:to_h)
  end
end
