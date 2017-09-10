class Array
  def map(*args, &proc)
    return self.clone.map(proc) unless proc.nil?
    copy = self.clone
    args.each do |arg|
      copy.map!(&arg)
    end
    copy
  end
end
