class Time
  def self.from_shadow(integer)
    Time.at(86400*integer).utc
  end
end

if __FILE__ == $PROGRAM_NAME
  puts Time.from_shadow(ARGV.first.to_i)
end
