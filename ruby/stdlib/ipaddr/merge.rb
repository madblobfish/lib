require 'ipaddr'

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
        return [self,other].sort
      end
    elsif self.include?(other) && other.prefix == 32
      return [self]
    elsif other.include?(self) && self.prefix == 32
      return [other]
    elsif other.include?(self)
      return [other]
    elsif self.include?(other)
      return [self]
    else
      return [self, other].sort
    end
  end

  def self.merge(*input)
    return [] if input.empty?
    return input if input.one?
    grps = input.group_by(&:ipv6?)
    if grps.count == 2
      return grps.flat_map{|_,ips| IPAddr.merge(*ips) }
    end
    ips = input
    merged = true
    while merged
      break if ips.one?
      merged = false
      merged_block = []
      mergers = []
      ips.combination(2) do |a,b|
        merged_block = a.merge(b)
        mergers = [a,b]
        if merged_block.one?
          merged = true
          break
        end
      end
      ips -= mergers
      ips += merged_block
    end

    return ips.sort
  end
  def to_cidr
    "#{self.to_s}/#{self.prefix}"
  end
end
a = IPAddr.new('10.0.4.12/32')
b = IPAddr.new('10.0.4.0/24')
c = IPAddr.new('10.0.5.0/24')
d = IPAddr.new('10.0.4.0/23')
e = IPAddr.new('10.0.0.0/16')
f = IPAddr.new('10.1.6.0/24')
raise 'AH1' unless a.merge(b) == [b]
raise 'AH2' unless b.merge(c) == [d]
raise 'AH3' unless e.merge(c) == [e]
raise 'AH4' unless c.merge(e) == [e]
raise 'AH5' unless d.merge(f) == [d,f]
raise 'AH6' unless a.merge(f) == [a,f]
raise 'AH7' unless IPAddr.merge(*[a,b,c,d,e,f]) == [e,f]

if __FILE__ == $PROGRAM_NAME
  ips = ARGV.flat_map{|f| File.readable?(f) ? File.readlines(f) : f}
  ips += STDIN.readlines unless STDIN.tty?
  ips.map!(&:strip)
  ips.sort!
  ips.uniq!
  if ips.one? || ips.empty?
    puts $PROGRAM_NAME + ' <ip addresses> [filelists]'
    puts 'takes multiple ip blocks or single ip\'s and merges them'
    puts ''
    puts 'example input: 10.0.0.2 10.0.0.1/25 10.0.0.128/26 10.0.0.192/26'
    exit
  end
  puts IPAddr.merge(*ips.map{|addr| IPAddr.new(addr)}).map(&:to_cidr)
end
