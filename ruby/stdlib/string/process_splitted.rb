class String
  def process_splitted(split_on = ' ', &proc)
    return proc.yield(self) if split_on.length == 0
    str = self.split(Regexp.new(split_on.chr))
    if split_on.length == 1
      str.map{|s| proc.yield(s)}
    else
      str.map{|s| s.process_splitted(split_on[1..], &proc)}
    end.join(split_on.chr)
  end
end

raise "AHHHH" unless "asd yo\nblabl".process_splitted(" \n"){|x|x.reverse} == "dsa oy\nlbalb"
raise "AHHHH" unless "asd yo\nblabl".process_splitted("\n "){|x|x.reverse} == "dsa oy\nlbalb"
