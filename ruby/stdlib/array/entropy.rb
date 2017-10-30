class Array
  # shannon entropy
  def entropy(dictionary_size = self.length, probablility_fun = nil)
    require_relative 'count_unique'
    counts = self.count_unique

    if dictionary_size.nil?
      counts.values.reduce(0){ |sum, item| sum + item * Math.log(item.to_f / dictionary_size, 2) }
    elsif probablility_fun.is_a?(Proc)
      counts.reduce(0){ |sum, item| sum + item[1] * Math.log(probablility_fun[item[0]], 2) }
    else
      counts.values.reduce(0){ |sum, item| sum + item * Math.log(item.to_f / dictionary_size, 2) }
    end
  end
end

class String
  # shannon entropy
  # @see: Array.entropy
  def entropy(dictionary_size = self.length, probablility_fun = nil)
    self.chars.entropy(dictionary_size, probablility_fun)
  end
end
