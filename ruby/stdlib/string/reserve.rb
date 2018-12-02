class String
  alias :orig_reverse :reverse
  def reverse(seperator=nil)
    return orig_reverse unless seperator.is_a? String
    split(seperator).reverse.join(seperator)
  end
end

# minimal testcases
raise "" unless "as,d,co,l".reverse == "l,oc,d,sa"
raise "" unless "as,d,co,l".reverse(",") == "l,co,d,as"
