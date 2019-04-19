class Duration
  private
  def self.gen_lambda(factor, max)
    reverse = lambda{|sec| sec * factor}
    return [lambda{|sec| (sec / factor).floor}, reverse] unless max
    [lambda{|sec| (sec / factor).floor % max}, reverse]
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
  def initialize(seconds)
    @sec = seconds
  end
  def abs
    Duration.new(sec.abs)
  end
  def to_i; @sec.to_i; end
  def to_f; @sec.to_f; end
  def to_s
    [@sec.negative? ? "-" : nil, SIZES_AND_FACTORS.map do |name, calc|
      [name.to_s, calc[0][@sec.abs].to_s]
    end.map do |name, size|
      size << name unless size == "0"
    end].join
  end
  alias :inspect :to_s
  def self.parse(duration)
    positive = duration.delete!('-').nil?
    sec = 0
    while not duration.empty?
      duration.gsub!(/^(\d+)(\D+)/,'')
      raise "can't parse" unless $1 and $2
      sec += SIZES_AND_FACTORS[$2.to_sym][1][$1.to_i]
    end
    self.new(positive ? sec : -sec)
  end
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
raise "implementation error" unless (a - b).to_s.abs == "10s"
raise "implementation error" unless (b - a).to_s == "10s"
raise "implementation error" unless Duration.parse(a = "-1y4s2msec").to_s == a
raise "implementation error" unless Duration.parse(a).to_f == -1892160004.002
