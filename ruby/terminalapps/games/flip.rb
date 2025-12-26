require_relative '../lib/gamelib'

class Flip < TerminalGame
  def initialize(**opts)
    @mouse_support = true
    @fps = 2
    @size = opts.fetch(:size, 4)
    @map = Array.new(@size){Array.new(@size){false}}
    @start_time = Time.now
    @steps = 0
    @wrap = opts.fetch(:wrap, false)
  end

  def score
    [
      ' Steps: ', @steps,
      ' Time: %.2f' % (Time.now - @start_time),
      's'
    ].join('')
  end
  def draw
    move_cursor
    @map.each do |l|
      l.each do |f|
        print f ? '██' : '  '
      end
      puts "\r"
    end
    print score
  end

  def mouse_handler(y, x, button_id, dir)
    return if dir != :up
    y /= 2
    return draw if [x, y].any?{|c|c < 0 || c > @size-1}
    @draw_mutex.synchronize do
      @map[x][y] = ! @map[x][y]
      [
        [ 0, 1],
        [ 0,-1],
        [ 1, 0],
        [-1, 0],
      ].each do |(a,b)|
        begin
          if x+a > @size-1
            @map[0][y+b] = ! @map[0][y+b] if @wrap
          elsif x+a < 0
            @map[@size-1][y+b] = ! @map[@size-1][y+b] if @wrap
          elsif y+b > @size-1
            @map[x+a][0] = ! @map[x+a][0] if @wrap
          elsif y+b < 0
            @map[x+a][@size-1] = ! @map[x+a][@size-1] if @wrap
          else
            @map[x+a][y+b] = ! @map[x+a][y+b]
          end
        rescue
          # ignore
        end
      end
      draw
      check_win()
    end
  end

  def check_win
    raise TerminalGameEnd, 'won!' + score if @map.flatten.all?(true)
  end
end

if __FILE__ == $PROGRAM_NAME
  opts = {wrap: ARGV.delete('--wrap')}
  opts[:size] = ARGV[0].to_i if ARGV.length >= 1
  Flip.new(**opts).run()
end
