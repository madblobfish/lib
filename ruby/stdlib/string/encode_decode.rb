class String
  def b64e
    require 'base64'
    Base64.encode64(self)
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
end
