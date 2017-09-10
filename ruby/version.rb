Version = Gem::Version
class Version < Gem::Version
  include Comparable
  def <=>(other)
    if other.is_a?(String)
      self <=> Gem::Version.new(other)
    else
      super
    end
  end
end


# test
def fail
  require 'libexception.rb'
  raise LibException, 'Version: failed'
end

fail unless Version.new('0.4.1b') > Gem::Version.new('0.4.1a')
fail unless Version.new('0.4.1b') > '0.4.1a'
fail unless Version.new('0.4.1b') > Version.new('0.4.1a')
