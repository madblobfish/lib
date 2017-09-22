require 'ipaddr'

# inspired by http://www.pc-help.org/obscure.htm

class IPAddr
  public def [](index = 0..-1)
    if ipv4?
      to_string.split('.')[index]
    elsif ipv6?
      to_string.split(':')[index]
    else
      raise AddressFamilyError, "unsupported address family"
    end
  end

  private def to_a
    if ipv4?
      self[].map do |e|
        Integer(e, 10)
      end
    elsif ipv6?
      self[].map do |e|
        Integer(e, 16)
      end
    end
  end

  ##
  # Utility to generate various formatings of an IPv4 Address
  #
  #   Directive | Meaning
  #   --------------------------------
  #   d         | decimal number
  #   o         | octal number
  #   h         | hexadecimal number
  #   j,D       | joined decimal number
  #   H         | joined hexadecimal number
  #
  # Directives can be prefixed with a number from 1 to 9,
  # it tells the obfuscator to zerofill.
  #
  # Directives can be prefixed with a '+' (after the number)
  # which indicates that the value should be overflown (+256).
  #
  # two or more consecutive j's create one decimal encoded field.
  # '+' and the number is ignored for the later ones.
  #
  # Examples:
  # IPAddr.new('127.0.0.1').obfuscate('jjjh') #=> "8323072.0x1"
  # IPAddr.new('127.0.0.1').obfuscate('jjjj') #=> "2130706433"
  # IPAddr.new('127.0.0.1').obfuscate('+d4ddh') #=> "383.0000.0.0x1"
  public def obfuscate(recipe)
    raise AddressFamilyError, "only IPv4 supported" unless ipv4?
    unless /\A([1-9]?\+?[dohjHD]){4}\z/ =~ recipe
      raise ArgumentError, 'invalid format string'
    end

    regexp = /\A(?<digit>\d?)(?<plus>\+?)(?<name>[dohjHD])/
    ret = ''
    idx = 0

    while match = recipe.match(regexp)
      recipe.gsub!(regexp, '')
      current_value = to_a[idx]
      current_value += 256 if match[:plus] && match[:plus] != '' # overflow
      string = case match[:name]
        when 'd'
          string = current_value.to_s
        when 'o'
          string = '0' << current_value.to_s(8)
        when 'h'
          string = '0x' << current_value.to_s(16)
        when 'j', 'D', 'H'
          n = recipe.match(/\A(\d?\+?#{match[:name]})+/).to_s.count(match[:name])
          n.times do |i|
            idx += 1
            current_value = current_value << 8
            current_value += to_a[idx]
            recipe.gsub!(regexp, '')
          end
          if match[:name] == 'H'
            '0x' << current_value.to_s(16)
          else
            current_value.to_s(10)
          end
        end
      if match[:digit] && match[:digit] != '' # padding
        pad_len = Integer(match[:digit], 10)
        string = ('0' * (pad_len - string.length)) << string rescue string
      end
      ret << string << '.'
      idx += 1
    end
    raise ArgumentError, 'recipe broken: ' << recipe unless recipe.empty?
    return ret.chop!
  end
end


if __FILE__ == $PROGRAM_NAME
  # script mode
  if ARGV.empty?
    puts "Enter Ip Address to obfuscate"
    exit
  end
  ARGV.each do |addr|
    ip = IPAddr.new(addr)
    variants = []
    variants << ip.hton
    variants << ip.to_i.to_s
    variants << ip.to_s
    variants << ip.to_string
    if ip.ipv4?
      variants << ip.ipv4_compat.to_s
      variants << ip.ipv4_compat.to_string
      variants << ip.ipv4_mapped.to_s
      variants << ip.ipv4_mapped.to_string
      variants << ip.obfuscate('hhhh')
      variants << ip.obfuscate('oooo')
      variants << ip.obfuscate('oojj')
      variants << ip.obfuscate('ojjj')
      variants << ip.obfuscate('jjjj')
      variants << ip.obfuscate('+jjjj')
      variants << ip.obfuscate('HHHH')
      variants << ip.obfuscate('+HHHH')
      variants << ip.obfuscate('HHDD')
      variants << ip.obfuscate('d+dd+d')
      variants << ip.obfuscate('+hojj')
      # ...
    elsif ip.ipv6?
      if ip != ip.native
        variants << ip.native
        ARGV << ip.native
      end
    end
    puts variants.uniq
  end
end
