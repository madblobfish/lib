require 'ipaddr'

class IPAddr
  alias :to_s_orig :to_s
  def to_s(b=nil)
    if b == 2
      if self.ipv4?
        ('%032b' % self.to_i).split("").each_slice(8).map(&:join).join(".")
      elsif self.ipv6?
        raise ArgumentError, 'AHHHHHH, not implemented! yet'
      else
        raise ArgumentError, 'AHHHHHH'
      end
    elsif ! b.nil?
      raise ArgumentError, 'only 2 or nil accepted'
    else
      to_s_orig
    end
  end
end
