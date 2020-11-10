require 'openssl'
require 'base64'

# Written out of pure hate that this does not exist (to my knowledge)
#
# Notes:
# * This implementation is only an example
# * It does not implement proper error handling!
# * Do not return different errors to third parties!
# * It is most probably not side channel free!
# * Use the current (D)TLS if you have an interactive channel
class Aes128CbcHmacSha256Etm
  DEFAULT_PACK = lambda{|c, ad| [c,ad].map{|e| Base64.strict_encode64(e)}.join('$') }
  DEFAULT_UNPACK = lambda{|s| s.b.split('$').map{|e| Base64.strict_decode64(e)}}
  DEFAULT_HASH_PACK = lambda{|c, h| c.to_s << [h].pack('H*')}
  DEFAULT_HASH_UNPACK = lambda{|s| [s.b[0...-32], s.b[-32..-1].unpack('H*')[0]]}

  def initialize(key, **o)
    @pack = o.fetch(:pack, DEFAULT_PACK)
    @unpack = o.fetch(:unpack, DEFAULT_UNPACK)
    @hash_pack = o.fetch(:hash_pack, DEFAULT_HASH_PACK)
    @hash_unpack = o.fetch(:hash_unpack, DEFAULT_HASH_UNPACK)

    dkey = [OpenSSL::HMAC.hexdigest('SHA256', key, key)].pack("H*")
    encryption_key = dkey[0...16]
    authentication_key = dkey[16...32]

    cipher = OpenSSL::Cipher::AES128.new(:CBC)
    @cipher = lambda do |enc|
      cipher.reset
      enc ? cipher.encrypt : cipher.decrypt
      cipher.key = encryption_key
      cipher
    end
    @mac = lambda{|s| OpenSSL::HMAC.hexdigest('SHA256', authentication_key, s) }
  end

  def encrypt(plaintext, **o)
    cipher = @cipher[true]
    cipher.iv = iv = o.fetch(:iv, cipher.random_iv)

    ciphertext = iv << cipher.update(plaintext) << cipher.final

    packed = @pack[ciphertext, o.fetch(:associated_data, '')]

    @hash_pack[packed, @mac[packed]]
  end

  def decrypt(crypted, **o)
    packed, hash = @hash_unpack[crypted]

    raise 'AAHHH' unless hash == @mac[packed]

    ciphertext, associated_data = @unpack[packed]

    cipher = @cipher[false]
    cipher.iv = ciphertext[0...16]

    plaintext = cipher.update(ciphertext[16..-1]) << cipher.final

    [plaintext, associated_data]
  end
end
class Encrypt < Aes128CbcHmacSha256Etm
end

a = Aes128CbcHmacSha256Etm.new('1234567890123456')
raise 'testfail' if a.decrypt(a.encrypt('yoyo')) != ['yoyo', nil]
raise 'testfail' if a.decrypt(a.encrypt('yoyo', associated_data: 'hihi')) != ['yoyo', 'hihi']
#raise 'testfail' if a.encrypt('yoyo', iv: "\"\xF5GN\xEF\x0F'_\xB4\x0F\n\xF2\xFAY\xCE\xE1".b) != "IvVHTu8PJ1+0Dwry+lnO4THJmig2r5sdhq8BW1gHNx8=$\x8B\xD8q?\b4\xC9\x89k\xF1\xB6\xDFo\xE3\x89 \xF8\x17\xC5\x90\x16\xBB]\x042\x99\t\x1F\xB3\x0Euo".b

# example of a letter with verified headers and nice formatting
a = Aes128CbcHmacSha256Etm.new('1234567890123456',
  pack: lambda do |c,ad|
    ad << "\n\n" << Base64.strict_encode64(c)
  end,
  unpack: lambda do |s|
    r = s.split("\n\n", 2)
    [Base64.strict_decode64(r[1]), r[0]]
  end
)
#raise 'testfail' if a.encrypt('hi', associated_data: "Recipient: my secret love\nRespond To: you know who", iv: "\"\xF5GN\xEF\x0F'_\xB4\x0F\n\xF2\xFAY\xCE\xE1".b) != "Recipient: my secret love\nRespond To: you know who\n\nIvVHTu8PJ1+0Dwry+lnO4WpvcMTmmXx6MsadQ/RAuw4=I!\xC1\xCDt\x83\xC3\x92I\xE3\xF0\xD0\xDB\x02W\xC0\xFFE\xB5\xA9\xB4\xE5K\x8D\xDDj\a^\xE2d\r%".b
#raise 'testfail' if a.decrypt(a.encrypt('hi', associated_data: "Recipient: my secret love\nRespond To: you know who")) != ['hi', "Recipient: my secret love\nRespond To: you know who"]

if ARGV[0] == '-d'
  inp = if ARGV.length == 3
      File.read(ARGV[2])
    else
      STDIN.read
    end
  print Aes128CbcHmacSha256Etm.new(ARGV[1]).decrypt(inp)[0]
elsif ARGV[0] == '-e'
  inp = if ARGV.length == 3
      File.read(ARGV[2])
    else
      STDIN.read
    end
  print Aes128CbcHmacSha256Etm.new(ARGV[1]).encrypt(inp)
end
