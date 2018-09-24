require 'openssl'
require 'base64'

# written out of pure hate that this does not exist (to my knowledge)
class Aes128CbcHmacSha256Etm
  DEFAULT_PACK = lambda{|c, ad| [c,ad].map{|e| Base64.strict_encode64(e)}.join("$") }
  DEFAULT_UNPACK = lambda{|s| s.split('$').map{|e| Base64.strict_decode64(e)}}
  DEFAULT_HASH_PACK = lambda{|c, h| "#{c}@#{h}"}
  DEFAULT_HASH_UNPACK = lambda{|s| s.split('@')}

  def initialize(key, **o)
    @key = key
    @pack = o.fetch(:pack, DEFAULT_PACK)
    @unpack = o.fetch(:unpack, DEFAULT_UNPACK)
    @hash_pack = o.fetch(:hash_pack, DEFAULT_HASH_PACK)
    @hash_unpack = o.fetch(:hash_unpack, DEFAULT_HASH_UNPACK)

    @cipher = OpenSSL::Cipher::AES128.new(:CBC)
  end

  def inspect
    '#<Aes128CbcHmacSha256Etm>'
  end

  def encrypt(plaintext, **o)
    @cipher.reset
    @cipher.encrypt
    @cipher.key = @key
    iv = o.fetch(:iv, @cipher.random_iv)
    @cipher.iv = iv

    ciphertext = iv << @cipher.update(plaintext) << @cipher.final

    packed = @pack[ciphertext, o.fetch(:associated_data, '')]

    hash = OpenSSL::HMAC.hexdigest('SHA256', @key, packed)

    @hash_pack[packed, hash]
  end

  def decrypt(crypted, **o)
    packed, hash = @hash_unpack[crypted]

    raise 'AAHHH' unless hash == OpenSSL::HMAC.hexdigest('SHA256', @key, packed)

    ciphertext, associated_data = @unpack[packed]

    @cipher.reset
    @cipher.decrypt
    @cipher.key = @key
    @cipher.iv = ciphertext[0...16]

    plaintext = @cipher.update(ciphertext[16..-1]) << @cipher.final

    [plaintext, associated_data]
  end
end
class Encrypt < Aes128CbcHmacSha256Etm
end

a = Aes128CbcHmacSha256Etm.new('1234567890123456')
raise 'testfail' if a.decrypt(a.encrypt('yoyo')) != ['yoyo', nil]
raise 'testfail' if a.decrypt(a.encrypt('yoyo', associated_data: 'hihi')) != ['yoyo', 'hihi']
raise 'testfail' if a.encrypt("yoyo", iv: "\"\xF5GN\xEF\x0F'_\xB4\x0F\n\xF2\xFAY\xCE\xE1".b) != 'IvVHTu8PJ1+0Dwry+lnO4THJmig2r5sdhq8BW1gHNx8=$@8bd8713f0834c9896bf1b6df6fe38920f817c59016bb5d043299091fb30e756f'

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
raise 'testfail' if a.decrypt(a.encrypt('hi', associated_data: "Recipient: my secret love\nRespond To: you know who")) != ["hi", "Recipient: my secret love\nRespond To: you know who"]
