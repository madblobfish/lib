class Duration
  private
  def self.gen_lambda(factor, max)
    return lambda{|sec| (sec / factor).floor} unless max
    lambda{|sec| (sec / factor).floor % max}
  end

  SIZES_AND_FACTORS = {
    y: gen_lambda(60*60*60*24*365, nil),
    d: gen_lambda(60*60*60, 24),
    h: gen_lambda(60*60, 60),
    m: gen_lambda(60, 60),
    s: gen_lambda(1, 60),
    msec: gen_lambda(0.001, 1000),
  }
  public
  attr_reader :sec
  attr_reader :negative
  def initialize(seconds)
    @sec = seconds.abs
    @negative = seconds.negative?
  end
  def to_i; @sec.to_i; end
  def to_f; @sec.to_f; end
  def to_s
    [@negative ? "-" : nil, SIZES_AND_FACTORS.map do |name, calc|
      [name.to_s, calc[@sec].to_s]
    end.map do |name, size|
      size << name unless size == "0"
    end].join
  end
  alias :inspect :to_s
  # Todo: def parse(Duration string)
end

class Time
  alias :"old_minus" :"-"
  def -(other)
    return self.old_minus(other) unless other.is_a?(Time)
    Duration.new((self.to_f - other.to_f))
  end
end

# tests
a = Time.now()
b = a + 10
raise "implementation error" unless (a - b).to_s == "-10s"
raise "implementation error" unless (b - a).to_s == "10s"
