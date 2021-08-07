
class GeoCoord
  EARTH_RADIUS = 6371
  PRECISION = 0.000000001
  attr_reader :lat, :lon
  attr_writer :precision
  def initialize(lat, lon, lat_min=0, lon_min=0, lat_sec=0, lon_sec=0)
    @lat = (lat + lat_min/60.0 + lat_sec/60.0/60) * (Math::PI/180)
    @lon = (lon + lon_min/60.0 + lon_sec/60.0/60) * (Math::PI/180)
    @precision = PRECISION
  end
  # returns meters
  # source https://edwilliams.org/avform147.htm#Dist
  def distance_to(other)
    2*Math.asin(Math.sqrt(
      (Math.sin((lat-other.lat)/2.0))**2 + 
      Math.cos(lat)*Math.cos(other.lat)*(Math.sin((lon-other.lon)/2.0))**2
    )) * EARTH_RADIUS
  end
  def self.from_str(str)
    GeoCoord.new(
      *case str
      when /\A\s*(\d+)\s*°\s*(\d+)\s*'\s*([0-9,.]+)\s*"(?:\s*,)?\s*N\s*(\d+)\s*°\s*(\d+)\s*'\s*([0-9,.]+)\s*"\s*W\s*\z/
        [$1,$4, $2,$5, $3,$6]
      when /\A\s*(\d+)\s*°\s*([0-9,.]+)\s*'(?:\s*,)?\s*N\s*(\d+)\s*°\s*([0-9,.]+)\s*'\s*W\s*\z/
        [$1,$3, $2,$4]
      when /\A\s*([0-9,.]+)\s*°\s*N(?:\s*,)?\s*([0-9,.]+)\s*°\s*W\s*\z/
        [$1, $2]
      when /\A(?:\s*\+)?\s*([0-9,.]+)(?:\s*,\s*|\s+)(?:-\s*)?([0-9,.]+)\s*\z/
        [$1, $2]
      else
        raise "AHH! #{str.inspect}"
      end.map{|s|s.tr(',', '.').to_f}
    )
  end
  def to_s(format=:deg)
    "#{@lat/(Math::PI/180)}° N #{@lon/(Math::PI/180)}° W"
  end
  # close enough
  def ==(other)
    lat.rationalize(PRECISION) == other.lat.rationalize(PRECISION) &&
    lon.rationalize(PRECISION) == other.lon.rationalize(PRECISION)
  end
end

# some tests
raise "AH" unless (GeoCoord.new(50.66757, 17.92194).distance_to(GeoCoord.new(50.67061,17.92198))*1000).rationalize(0.000001) == Rational("396526/1173")
raise "AHH" unless GeoCoord.new(62, 7, 26.922,1.938).distance_to(GeoCoord.new(64,21, 8,56,  45.528,32)).to_i == 766
[
  "32.30642° N 122.61458° W",
  " 32,30642 °N 122,614580°W",
  "+32.30642, -122.61458",
  "32° 18.3852' N 122° 36.8748' W ",
  "32° 18' 23.112\" N 122° 36' 52.488\" W ",
].each{|s| raise "AHHH" unless (GeoCoord.from_str(s)) == (GeoCoord.new(32.30642, 122.61458))}

if __FILE__ == $PROGRAM_NAME
  if ARGV.empty? || ARGV.include?('--help')
    print $PROGRAM_NAME
    puts ' coord1 [coord2]'
    puts '1 arg: normalizes to degrees and probably throws away some details'
    puts '2 args: calculates distance in meters'
    exit
  end
  if ARGV.one?
    puts GeoCoord.from_str(ARGV.pop)
  else
    puts GeoCoord.from_str(ARGV.pop).distance_to(GeoCoord.from_str(ARGV.pop))*1000
  end
end
