class Method
  ##
  # convert a string describing a method to a source location
  #
  #
  # # => instance method
  # . => normal method on class
  # :: => namespace
  def self.str_to_loc(meth_string)
    case meth_string
    when /[.#].*[.#]/
      raise ArgumentError, 'more than one # or . in the method string'
    when /\./
      sp = meth_string.split('.')
      class_or_module = eval(sp[0]) # I'm really unhappy about this eval!
      class_or_module.methods(true).each do |m|
        meth = class_or_module.method(m)
        loc = meth.source_location
        if sp[1].to_sym == m && loc
          # other stuff
          return "#{loc.join(':')} (#{meth.name})"
        end
      end
    when /#/
    else
      raise ArgumentError, 'no method'
    end
    raise StandardError, 'FAIIIL'
  end
end


