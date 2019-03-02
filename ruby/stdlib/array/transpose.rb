class Array
  def transpose
    self.reduce(Array.new(self.map(&:length).max){[]}){|m,a| a.each_with_index{|x,i| m[i] << x}; m}
  end
  def transpose_string
    self.map{|x|x.split('')}.transpose.map(&:join)
  end
end

raise "ah!" unless (x = [[3,2,1,0],[9,8,7,6]]).transpose.transpose == x
