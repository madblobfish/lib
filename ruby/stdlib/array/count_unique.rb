class Array
  def count_unique
    self.each_with_object(Hash.new(0)){|i,h| h[i] += 1}
  end
end
