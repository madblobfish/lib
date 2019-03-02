class String
  def pkcs7_pad(bs=16)
    n = bs.modulo(self.length)
    self.b + ('' << n).b * n
  end
  # do not use this! its vulnerable
  def pkcs7_unpad(bs=16)
    n = self.byteslice(-1).unpack("C").first
    raise "A string length broken" if self.length.modulo(bs) != 0
    raise "AH padding bigger than blocksize" if n > bs
    raise "AHH string too short" if self.length <= n
    raise "AHHH not padded correctly" if self[-n, n].each_byte.any?{|x|x != n}
    self[0..-n-1]
  end
end
