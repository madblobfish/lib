require_relative 'version.rb'

describe Version do
  it 'should convert strings to versions' do
    expect(Version.new('0.4.1b')).to eq('0.4.1b')
    expect(Version.new('0.4.1b') > '0.4.1a').to be_truthy
  end

  it 'should ' do
    expect(Version.new('0.4.1b') > Gem::Version.new('0.4.1a')).to be_truthy
  end

  it 'should fail when converting invalid version numbers' do
    expect{Version.new('0.4.1b') > 'A'}.to raise_error(ArgumentError)
  end

  it 'should ' do
    expect(Version.new('0.4.1b') > Version.new('0.4.1a')).to be_truthy
  end
end
