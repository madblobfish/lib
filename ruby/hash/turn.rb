class Hash
  def turn
    out = {}
    self.each_pair do |e,i|
      if out.has_key? i
        out[i] << e
      else
        out[i] = [e]
      end
    end
    out
  end
end

class Hash
  def turn
    self.each_with_object(Hash.new{Array.new}){|(n,v),h| h[v]+=[n]}
  end
end


# test
unless {a:1,b:2,c:1}.turn == {1:[:a,:c], 2:[:b]}
  require '../libexception.rb'
  raise LibException, 'Hash.turn: broken'
end
