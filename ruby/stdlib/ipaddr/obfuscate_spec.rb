require_relative 'obfuscate.rb'
require 'rspec'

describe IPAddr do
  ips = %w(127.0.0.1 255.255.255.255).map{|e| IPAddr.new(e)}
  tes = %w(127.0.0.0x01 255.255.255.0xff)

  it 'obfuscate("dddd") equal the normal ip' do
    ips.each do |ip|
      expect(ip.obfuscate('dddd')).to eql(ip.to_string)
    end
  end

  it 'obfuscate("ddDD") merges the last two fields' do
    ips.each do |ip|
      expect(ip.obfuscate('ddDD')).to match(/\A\d+\.\d+\.\d+\z/)
    end
  end
  it 'obfuscate("ddoh") has octal and hex hex' do
    ips.each do |ip|
      expect(ip.obfuscate('ddoh')).to match(/\A\d+\.\d+\.0[0-7]+\.0x[0-9a-f]+\z/)
    end
  end
  it 'obfuscate("HHHH") is one hexadecimal number' do
    ips.each do |ip|
      expect(ip.obfuscate('HHHH')).to match(/\A0x[0-9a-f]+\z/)
    end
  end
  it 'obfuscate("9dddd") zerofills the first number to 9 digits' do
    ips.each do |ip|
      expect(ip.obfuscate('9dddd')).to match(/\A\d{9}\./)
    end
  end

  # prefixes
  it 'obfuscate with a single o field leads to a 0 prefix' do
    ips.each do |ip|
      expect(ip.obfuscate('oddd')).to match(/\A0[0-7]+\.\d+\.\d+\.\d+\z/)
      expect(ip.obfuscate('dddo')).to match(/\A\d+\.\d+\.\d+\.0[0-7]+\z/)
    end
  end

  # overflow
  it 'obfuscate with a + adds 255' do
    ips.each do |ip|
      expect(ip.obfuscate('+HHHH')).to match(/\A0x1[0-9a-f]{8}\z/)
      expect(ip.obfuscate('+hddd')).to match(/\A0x1[0-9a-f]{2}\.\d+\.\d+\.\d+\z/)
      expect(ip.obfuscate('+dddd')).to match(/\A(25[6-9]|2[6-9]\d|[3-4]\d\d|50\d|51[0-2])\.\d+\.\d+\.\d+\z/)
      expect(ip.obfuscate('+oddd')).to match(/\A0[0-7]+\.\d+\.\d+\.\d+\z/)
    end
  end

  it 'obfuscate does not modify recipe' do
    string = 'dddd'
    ips.first.obfuscate(string)
    expect(string).to eql('dddd')
  end

  it 'obfuscate can\'t do ipv6'  do
    expect{IPAddr.new('::').obfuscate('dddd')}.to raise_error(IPAddr::AddressFamilyError, "only IPv4 supported")
  end

  it 'rejects invalid format strings' do
    expect{ips.first.obfuscate('asd')}.to raise_error(ArgumentError, "invalid format string")
    expect{ips.first.obfuscate('!asd')}.to raise_error(ArgumentError, "invalid format string")
  end
end
