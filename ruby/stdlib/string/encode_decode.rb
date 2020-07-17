class String
  def b64e
    require 'base64'
    Base64.encode64(self).tr("\n",'')
  end
  def b64d
    require 'base64'
    Base64.decode64(self)
  end
  def tobit
    self.unpack("b*").first
  end
  def frombit
    [self].pack("b*")
  end
  def tohex
    self.unpack("H*").first
  end
  def fromhex
    [self].pack("H*")
  end
  def hex2b64
    self.fromhex.b64e
  end
  def b642hex
    self.b64d.tohex
  end
  # https://tools.ietf.org/html/rfc3986#section-2.3
  def urle(char_selector=/[^a-zA-Z0-9_.~-]/)
    self.b.gsub(char_selector){|chr|'%' + chr.bytes.first.to_s(16)}
  end
  def urld(enc=Encoding::UTF_8)
    self.b.gsub(/%\h\h/){|chr| chr[1..-1].to_i(16).chr}.force_encoding(enc)
  end
end
