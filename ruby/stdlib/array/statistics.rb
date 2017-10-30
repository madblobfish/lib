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
    self.sum / self.length
  end
end

class Array
  def stat
    minmax = self.minmax
    {
      min: minmax[0],
      average: self.average,
      median: self.median,
      max: minmax[1],
      sum: self.sum,
    }
  end
end
