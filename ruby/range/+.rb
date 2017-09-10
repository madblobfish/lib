class Range
  def +(other)
    case other
    when Array
      to_a + other
    when Range
      to_a + other.to_a
    else
      raise 'other has to be a Range or an Array'
    end
  end
end

# test
unless (0..9) + ('a'..'f') == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 'a', 'b', 'c', 'd', 'e', 'f']
  require '../libexception.rb'
  raise LibException, 'Range.+ broken'
end
