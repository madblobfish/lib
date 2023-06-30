require_relative '../lib/gamelib'

class Flip < TerminalGame
  def initialize(size=4)
    @mouse_support = true
    @fps = 2
    @size = size
    @map = Array.new(@size){Array.new(@size){rand >= 0.5 ? true : false}}
    @start_time = Time.now
    @steps = 0
  end
  def draw
    # check_win()
    move_cursor
    @map.each do |l|
      l.each do |f|
        print f ? '██' : '  '
      end
      puts "\r"
    end
    print ' Steps: ', @steps
    print ' Time: %.2f' % (Time.now - @start_time)
    print 's'
  end
  def mouse_handler(y, x, button_id, dir)
    return if dir != :up
    y /= 2
    return draw if [x, y].any?{|c|c < 0 || c > @size-1}
    @map[x][y] = ! @map[x][y]
    [
      [ 0, 1],
      [ 0,-1],
      [ 1, 0],
      [-1, 0],
    ].each do |(a,b)|
      begin
        if x+a > @size-1
          @map[0][y+b] = ! @map[0][y+b]
        elsif x+a < 0
          @map[@size-1][y+b] = ! @map[@size-1][y+b]
        elsif y+b > @size-1
          @map[x+a][0] = ! @map[x+a][0]
        elsif y+b < 0
          @map[x+a][@size-1] = ! @map[x+a][@size-1]
        else
          @map[x+a][y+b] = ! @map[x+a][y+b]
        end
      rescue
        # ignore
      end
    end
    draw
  end
end

if __FILE__ == $PROGRAM_NAME
  Flip.new().run()
end
