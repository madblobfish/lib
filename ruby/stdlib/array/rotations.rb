class Array
  def rotations
    length.times.map{|n| rotate(n)}
  end
end

# class String
#   def rotations
#     split("").rotations.map(&:join)
#   end
# end
