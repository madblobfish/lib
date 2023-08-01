class HuffmanCode
  def initialize arr
    @table = {}
    @tableInv = {}

    list = countDistinct(arr)

    while list.length > 1
      list = list.sort_by {|x| x[:value]}

      left = list.shift()
      right = list.shift()

      addToTable(left[:symbols], "0")
      addToTable(right[:symbols], "1")

      list.push({
        value: left[:value] + right[:value],
        symbols: left[:symbols].concat(right[:symbols])
      })
    end

    @tableInv = @table.invert
    return @table
  end

  def addToTable symbols, left
    symbols.each do |symbol|
      if @table[symbol].nil?
        @table[symbol] = left
      else
        @table[symbol].prepend(left)
      end
    end
  end
  private :addToTable

  def getTable
    return @table
  end

  # Extension Point
  def customEncoding str
    return str
  end

  # Extension Point
  def customDecoding str
    return str
  end

  def encode arr
    out = ""
    arr.each do |e|
      if @table[e].nil?
        raise 'Symbol not in encoding table!'
      end
      out += @table[e]
    end

    return customEncoding(out)
  end

  def decode str
    arr = []
    temp = ""

    customDecoding(str).each_char do |e|
      temp += e
      if @tableInv[temp]
        arr.push (@tableInv[temp])
        temp = ""
      end
    end

    if !temp.empty?
      raise "String did not decode correct"
    end

    return arr
  end

  def countDistinct arr
    count = {}
    arr.each do |e|
      if count[e].nil?
        count[e] = 1
      else
        count[e] += 1
      end
    end
    return count.map {|key, val| {symbols: [key], value: val}}
  end
  private :countDistinct
end


# more efficient when binary encoded
class HuffmanIntegerCompressed < HuffmanCode
  def customDecoding str
    return str.unpack("w")[0].to_s(2)
  end
  def customEncoding str
    return [str.to_i(2)].pack("w")
  end
end

class HuffmanB36 < HuffmanCode
  def customDecoding str
    return str.to_i(36).to_s
  end
  def customEncoding str
    return [str].to_i.to_s(36)
  end
end

# tests
# a = HuffmanCompressed.new("hallotesttest123asdasdwerwrfxxcyfe".each_char.to_a)
# b = a.encode("hallohallowas".each_char.to_a)
# a.decode(b)

# a = HuffmanB36.new("hallotesttest123asdasdwerwrfxxcyfe".each_char.to_a)
# b = a.encode("hallohallowas".each_char.to_a)
# a.decode(b)

# a = HuffmanCode.new("asdasdwerwrfxxcyfe".each_char.to_a)
# b = a.encode ["a","s","d"]
# puts b
# puts a.decode b

