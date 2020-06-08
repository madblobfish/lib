class Array
  # detects loops in arrays that start with the first index
  # it is okay if the end of the array is cut off as long as it loops at least once
  #
  # e.g. [1,2,1,2] => [1,2]
  # e.g. [1,2,1,2,1] => [1,2]
  def loops?
    loop_elements = [self.first]
    potential_loop_point = 1
    while potential_loop_point <= (self.length+1)/2
      loops = self.each_slice(potential_loop_point).to_a
      if loops.last.length != potential_loop_point
        if loops.pop.is_prefix_of(loops.first)
          if loops.uniq.length == 1
            return loops.first
          end
        end
      else
        if loops.uniq.length == 1
          return loops.first
        end
      end
      idx = self[(potential_loop_point+1)..].index(self.first)
      if idx.nil?
        return false
      end
      potential_loop_point = idx + potential_loop_point +1
    end
    return false
  end

  def is_prefix_of(other)
    self.zip(other).all?{|s, o| s == o}
  end
end
