class String
  L337Table = Hash.new{Array.new([nil])}
  L337Table['!'] = ['l','i'],
  L337Table['1'] = ['l','i'],
  L337Table['2'] = ['z'],
  L337Table['3'] = ['e'],
  L337Table['4'] = ['a'],
  L337Table['5'] = ['s'],
  # L337Table['6'] = [],
  L337Table['7'] = ['t'],
  L337Table['8'] = ['b'],
  L337Table['9'] = ['g'],
  L337Table['0'] = ['o']

  # reverses leetspeek, gives an array of canidates
  def de_leet()
    out = [""]
    self.each_char do |char|
      tabl = L337Table[char]
      if tabl.first.nil?
        out.map!{|e| e += char}
      elsif tabl.length == 1
        out.map!{|e| e += tabl.first}
      else
        store = out
        out = []
        tabl.each do |t|
          out += store.map{|e| e += t}
        end
      end
    end
    out
  end
end

require_relative '../libexception'
raise LibException unless "h3110".de_leet.include? "hello"
raise LibException unless "C001 H4X0R".de_leet.include? "Cool HaXoR"
