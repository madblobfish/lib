class IPAddr
  require_relative 'lowest'
  require_relative 'next_to?'
  def merge(other)
    if self.next_to?(other) && other.prefix == self.prefix
      ret = self.lowest
      ret.prefix = self.prefix - 1
      if ret.include?(self) && ret.include?(other)
        return [ret]
      else
        return [self,other]
      end
    elsif self.include?(other) && other.prefix == 32
      return [self]
    elsif other.include?(self) && self.prefix == 32
      return [other]
    elsif self.include?(other)
      return [other] if other.prefix > self.prefix
      return [self]
    else
      return [self, other]
    end
  end

  def self.merge(*input)
    require_relative 'include_block?.rb'

    if input.empty? || input.one?
      raise ArgumentError, "give me two or more IPAddr's!"
    end

    ips = input.dup.sort
    pos = 0
    while true
      before = ips[pos - 1]
      current = ips[pos]
      following = ips[pos + 1]
      if current.nil?
        break
      elsif (pos - 1).positive? && current.include_block?(before)
        ips.delete_at(pos - 1)
        next
      elsif current.include_block?(following)
        ips.delete_at(pos + 1)
        next
      end

      merg = current.merge before
      if merg.one?
        pos -= 1
        ips[pos - 1] = merg.first
        ips.delete_at pos
        next
      end

      pos +=1
    end

    return ips
  end
end

if __FILE__ == $PROGRAM_NAME
  if ARGV.empty? || ARGV.one?
    puts 'obfuscate.rb <ip addresses>'
    puts 'takes multiple ip blocks or single ip\'s and merges them'
    puts ''
    puts 'example input: 10.0.0.2 10.0.0.1/25 10.0.0.128/26 10.0.0.192/26'
    exit
  end
  IPAddr.merge(*ARGV.map{|addr| IPAddr.new(addr)}).sort.each do |addr|
    print addr.to_s, '/', addr.prefix, "\n"
  end
end
