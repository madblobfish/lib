class Point
  def initialize xy, size = ARGV[0]
    size = size.to_i - 1

    x, y = xy.split ','
    @x, @y = [x, y].map{ |e|
      e = e.to_i
      raise InitFailed, e unless e.between? 0, size
      e
    }
  end

  def cell_from_field field
    field[@y][@x]
  end

  def each_around
    around = [0, 1, -1].product [0, 1, -1]
    around.map{ |x, y|
      yield Point.new "#{@x + x},#{@y + y}" rescue nil
    }
  end
end
class InitFailed < StandardError;end
