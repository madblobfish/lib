require 'ipaddr'

class IPAddr
  def self.subtract(ips, toremove)
    return ips if toremove.empty?
    return [] if ips.empty?
    # remove all ips contained completely in toremove
    ips -= ips.select{|ip| toremove.first.include?(ip)}
    toremove.each do |removal|
      ips.each do |ip|
        if ip.include?(removal)
          ips -= [ip]
          (removal.prefix - (ip.prefix)).times do |i|
            canidate = ip.dup
            canidate.prefix += 1
            other = ip.to_range.last
            other.prefix = canidate.prefix
            if canidate.include?(removal)
              ips += [other]
              ip = canidate
            else
              ips += [canidate]
              ip = other
            end
          end
        end
      end
    end
    return ips
  end
end
a = IPAddr.new('10.0.4.12/32')
b = IPAddr.new('10.0.4.0/24')
c = IPAddr.new('10.0.5.0/24')
d = IPAddr.new('10.0.4.0/23')
e = IPAddr.new('10.0.0.0/16')
f = IPAddr.new('10.1.6.0/24')
raise 'AH1' if a.include?(IPAddr.new('10.15.80.0/20'))
# raise 'AH1' unless a.merge(b) == [b]
# raise 'AH2' unless b.merge(c) == [d]
# raise 'AH3' unless e.merge(c) == [e]
# raise 'AH4' unless c.merge(e) == [e]
# raise 'AH5' unless d.merge(f) == [d,f]
# raise 'AH6' unless a.merge(f) == [a,f]
# raise 'AH7' unless IPAddr.merge(*[a,b,c,d,e,f]) == [e,f]

if __FILE__ == $PROGRAM_NAME
  require_relative 'merge'
  if ARGV.size != 2
    puts $PROGRAM_NAME + ' <comma separated ips> <ip to substract>'
    puts 'takes two sets of ips or single ip\'s and substracts one from the other'
    puts ''
    puts 'example input: 10.0.0.0/8 10.0.0.1/24,10.0.0.128/26,10.0.0.192/26'
    exit
  end
  puts IPAddr.merge(*IPAddr.subtract(
    ARGV.first.split(',').map{|addr| IPAddr.new(addr)},
    IPAddr.merge(*ARGV.last.split(',').map{|addr| IPAddr.new(addr)}),
  )).map(&:to_cidr)
end
