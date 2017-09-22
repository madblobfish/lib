class Array
  def median
    if (self.length % 2) == 0
      self.sort[self.length / 2]
    else
      sorted = self.sort
      (sorted[(self.length - 1) / 2] + sorted[self.length / 2]) / 2.0
    end
  end
end

class Array
  def average
    self.reduce(0) do |m, o|
      m+o
    end / self.length
  end
end
