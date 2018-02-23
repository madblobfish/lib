class Array
  def rotations
    out = []
    length.times do |n|
      out << rotate(n)
    end
    out
  end
end

# class String
#   def rotations
#     split("").rotations.map(&:join)
#   end
# end
