class Array
  ##
  # Adds normal arguments to map.
  # The arguments are method names as symbols which are then applied in order.
  # If a block is given it will be applied last.
  # also makes the normal proc trick
  #   arr.map(&:to_s)
  # more easy because one can drop the &
  #
  # Examples:
  #   ["1.2.1","2.1.1","3.3.1"].map(:split,:first,:to_i){|i|}.max
  #   ["1", "2", "3"].map(:to_i) #=> [1,2,3]
  def map(*args, &proc)
    return super if args.empty?
    copy = self.clone
    args.each do |arg|
      copy.map!(&arg)
    end
    if block_given?
      copy.map(&proc)
    else
      copy
    end
  end
end


# test
def err
  require_relative '../libexception.rb'
  raise LibException, 'Array.map: broken'
end

# new functionality
err unless [
    "one two 5",
    "three derp 3",
    "last first 2"
  ].map(:split,:last,:to_i){|i|i*2} == [10, 6, 4]
err unless  ["1", "2", "3"].map(:to_i) == [1,2,3]

# make sure old usage works
err unless [1,2,3].map{|e| e**2 } == [1,4,9]
err unless  ["1", "2", "3"].map(&:to_i) == [1,2,3]

err = nil
