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
