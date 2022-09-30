class GeoCoord
  EARTH_RADIUS = 6371008.7714 # earth mean radius
  PRECISION = 0.000000001
  GRAD2RAD = Math::PI / 180.0
  RAD2GRAD = 180.0 / Math::PI
  attr_reader :lat, :lon
  attr_writer :precision
  def initialize(lat, lon, lat_min=0, lon_min=0, lat_sec=0, lon_sec=0)
    @lat = (lat + lat_min/60.0 + lat_sec/60.0/60) * GRAD2RAD
    @lon = (lon + lon_min/60.0 + lon_sec/60.0/60) * GRAD2RAD
    @precision = PRECISION
  end

  # https://stackoverflow.com/a/19398136
  def self.area_of_polygon(points)
    points.pop() if points.first == points.last
    angles = points.cycle.each_cons(3).take(points.length).map do |before, own, after|
      a = own.greatCircleBearing(before)
      b = own.greatCircleBearing(after)
      Math.acos(Math.cos(-a)*Math.cos(-b) + Math.sin(-a)*Math.sin(-b))
    end
    ((angles.sum - (points.length - 2)*Math::PI) * (EARTH_RADIUS**2))
  end

  def greatCircleBearing(other)
    GeoCoord.greatCircleBearing(self.lat, self.lon, other.lat, other.lon)
  end
  def self.greatCircleBearing(lat1, lon1, lat2, lon2)
    dlon = lon1 - lon2
    Math.atan2(
      Math.cos(lat2)*Math.sin(dlon),
      Math.cos(lat1)*Math.sin(lat2) - Math.sin(lat1)*Math.cos(lat2)*Math.cos(dlon)
    )
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
      when /\A\s*(-?[0-9,.]+)\s*°\s*N(?:\s*,)?\s*(-?[0-9,.]+)\s*°\s*W\s*\z/
        [$1, $2]
      when /\A(?:\s*\+)?\s*(-?[0-9,.]+)(?:\s*,\s*|\s+)(?:-\s*)?(-?[0-9,.]+)\s*\z/
        [$1, $2]
      else
        raise "AHH! #{str.inspect}"
      end.map{|s|s.tr(',', '.').to_f}
    )
  end
  def to_s(format=:deg)
    "#{(@lat/GRAD2RAD)}° N #{(@lon/GRAD2RAD)}° W"
  end
  # close enough
  def ==(other)
    lat.rationalize(@precision) == other.lat.rationalize(@precision) &&
    lon.rationalize(@precision) == other.lon.rationalize(@precision)
  end
end

# some tests
raise "AH" unless (GeoCoord.new(50.66757, 17.92194).distance_to(GeoCoord.new(50.67061,17.92198))).rationalize(0.000001) == Rational("256576/759")
raise "AHH" unless GeoCoord.new(62, 7, 26.922,1.938).distance_to(GeoCoord.new(64,21, 8,56,  45.528,32)).to_i == 766566
[
  "32.30642° N 122.61458° W",
  " 32,30642 °N 122,614580°W",
  "+32.30642, -122.61458",
  "32° 18.3852' N 122° 36.8748' W ",
  "32° 18' 23.112\" N 122° 36' 52.488\" W ",
].each{|s| raise "AHHH" unless (GeoCoord.from_str(s)) == (GeoCoord.new(32.30642, 122.61458))}
colorado = %w(37.0,-102.05 41.0,-102.05 41.0,-109.05 37.0,-109.05)
raise "AHHHH" unless GeoCoord.area_of_polygon(colorado.map{|p|GeoCoord.from_str(p)}).rationalize(0.000001) == Rational("4406173680806817/16384")

if __FILE__ == $PROGRAM_NAME
  if ARGV.empty? || ARGV.include?('--help')
    print $PROGRAM_NAME
    puts ' coord1 [coord2]'
    puts '1 arg: normalizes to degrees and probably throws away some details'
    puts '2 args: calculates distance in m'
    puts '3+ args: calculates area under a polygon in m^2'
    exit
  end
  case ARGV.size
  when 1
    puts GeoCoord.from_str(ARGV.pop)
  when 2
    puts GeoCoord.from_str(ARGV.pop).distance_to(GeoCoord.from_str(ARGV.pop))
  else
    puts GeoCoord.area_of_polygon((ARGV.map{|x| GeoCoord.from_str(x)}))
  end
end
