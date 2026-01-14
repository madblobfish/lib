require_relative '../lib/gamelib.rb'
if (File.readable?('music/tetrinal.ogg') || File.readable?('music/tetrinal.wav')) && !ARGV.delete('--no-music')
  begin
    require_relative '../../stdlib/wav.rb'
    require_relative '../../stdlib/pa.rb'
    $music = Thread.new do
      `ffmpeg -i music/tetrinal.ogg music/tetrinal.wav` unless File.readable?('music/tetrinal.wav')
      buff, meta = wave_read(File.open('music/tetrinal.wav'))
      meta[:loop] = true
      PulseSimple.play_buffer(buff.read(meta[:size]), **meta)
    end
  # rescue
    # ignore
  end
end


# theese are my dirty little secrets:
class Array
  def rotate_clock
    self.transpose.map(&:reverse)
  end
  def add(other)
    [self, other].transpose.map(&:sum)
  end
  def sub(other)
    [self, other].transpose.map{|x|x.reduce(:-)}
  end
end
class Hash
  def rotate!
    sx = self[:size][1]
    self.transform_keys!{|y,x| x.nil? ? y : [sx-x, y]}
    self[:size].reverse!
  end
end

class Tetrinal < TerminalGame
  TETRIS_TILES_NORMAL = [
    "    \n    \n####    \n    ",
    "   \n###\n#  ",
    "   \n###\n  #",
    "   \n###\n # ",
    "##\n##",
    "  #\n ##\n # ",
    " # \n ##\n  #",
  ]
  TETRIS_TILES_NUMBERS = [
    "###\n# #\n# #\n# #\n###",
    "## \n # \n # \n # \n###",
    "###\n  #\n # \n#  \n###",
    "###\n  #\n ##\n  #\n###",
    "# #\n# #\n###\n  #\n  #",
    "###\n#  \n###\n  #\n###",
    "#  \n#  \n###\n# #\n###",
    "###\n  #\n  #\n  #\n  #",
    "###\n# #\n###\n# #\n###",
    "###\n# #\n###\n  #\n ##"
  ]
  EMPTY_CELL = {symbol:'⬛', color: [50,50,50]}
  def initialize(**opts)
    @board = Hash.new
    @size = [opts.fetch(:size_y, 20), opts.fetch(:size_x, 9)]
    @fps = 3
    @start = Time.now()
    @speedup = opts.fetch(:speedup, "stepped")
    @tiles_break = opts.fetch(:tiles_break, false)
    @tileset = TETRIS_TILES_NORMAL
    @tileset = TETRIS_TILES_NUMBERS if opts[:numbers]
    @tile_current = gen_tile
    @tile_next = gen_tile
    @sync = false
    @score = 0
    @random = opts[:random] ? true : false
    @mutex_draw = Mutex.new
    @mutex_drop = Mutex.new
  end

  def game_exit(e=nil)
      exit!(0)
  end
  def game_quit
    raise TerminalGameEnd, "quit (Score #{@score})"
  end

  def fps
    case @speedup
    when 'time'
      (Time.now() - @start) / 50.0 + 2 + ( @score / 1000.0)
    when 'none'
      3
    else #when 'stepped'
      case @score
      when 1..500
        2.5
      when 500..1000
        3
      when 1000..2000
        4
      when 2000..5000
        5
      when 5000..10000
        6
      when 10000..30000
        7
      else
        9
      end
    end
  end

  def gen_tile
    color = rand(9..14)
    elem = {}
    tile = @tileset.sample
    if @random
      tile = Array.new(rand(4)+rand(2)+1){|a| Array.new(rand(4)+rand(2)+1){' '}}
      tile.each_with_index.flat_map{|e, i| e.each_with_index.map{|e,j| [i,j]} }.sample( rand(5)+rand(5)+1).each do |i,j|
        tile[i][j] = '#'
      end
      tile = tile.map{|e| e.join('') }.join("\n")
      # tile = Array.new(rand(3)+1){|a| Array.new(rand(3)+1){|a| rand(2) == 1 ? '#' : ' '}.join('') }.join("\n")
    end
    tile.split("\n").each_with_index{|s,i| s.split('').each_with_index{|s,j| elem[[i,j]] = {symbol:'██', color: color} if s == '#'; elem[:size] = [i,j]}}
    elem[:size] = [0,0].zip(*elem.keys.reject{|k|k.is_a?(Symbol)}).map(&:max)
    rand(0..3).times{elem.rotate!}
    elem[:pos] = [-2, @size[1] / 2 -1]
    # raise elem.to_s
    elem
  end

  def current_tile_remove_connected
    changed = true
    while changed
      changed = false
      (@tile_current.dup).each do |k,v|
        next unless k.is_a?(Array)
        pos = k.add(@tile_current[:pos])
        dir = [[1,0], [0,1], [0,-1], [-1,0]]
        dir = [[1,0]] if @tiles_break == :unless_supported
        dir.each do |d|
          if !@tiles_break || @board.has_key?(pos.add(d)) || pos[0] +1 >= @size[0]
            @board[pos] = v
            @tile_current.delete(k)
            changed = true
          end
        end
      end
    end
  end

  def current_tile_stuck
    # stuck in other block
    return true if @board.any?{|k,v| @tile_current[k.sub(@tile_current[:pos])] rescue false}
    # stuck on ground
    return true if @tile_current.any?{|k,v| k.is_a?(Array) ? (k.add(@tile_current[:pos])[0]) >= @size[0] : false}
    # stuck left
    return true if @tile_current.any?{|k,v| k.is_a?(Array) ? (k.add(@tile_current[:pos])[1]) < 0 : false}
    # stuck right
    return true if @tile_current.any?{|k,v| k.is_a?(Array) ? (k.add(@tile_current[:pos])[1]) >= @size[1] : false}
    false
  end

  def drop_current_tile(useraction=false, completely=false)
    @mutex_drop.synchronize do
      begin
        @tile_current[:pos][0] += 1
        if current_tile_stuck
          @tile_current[:pos][0] -= 1
          current_tile_remove_connected
          if @tile_current.select{|k,v| k.is_a?(Array)}.none?
            next_tile
            return
          end
        else
          @score += completely ? 3 : 1 if useraction
        end
      end while completely
    end
  end

  def next_tile
    clear
    @tile_current.each{|k,v| @board[k.add(@tile_current[:pos])] = v if k.is_a?(Array)}
    @tile_current = @tile_next
    @tile_next = gen_tile
    rows_removed = 0
    @board.group_by{|(y,x),_| y}.select{|k,v| v.count == @size[1]}.map do |(y,x),v|
      v.map{|x|@board.delete(x.first)}
      rows_removed += 1
      y
    end.sort.each{|ymax| @board.transform_keys!{|y,x| [y <= ymax ? y+1 : y, x]}}
    @score += [0, 100, 250, 500, 1500][rows_removed]
    raise TerminalGameEnd, "you lost (Score: #{@score})" if current_tile_stuck
  end

  def block_to_str(block)
    return ' ' if block[:symbol] == ' '
    "#{get_color_code(block[:color])}#{block[:symbol]}#{get_color_code()}"
  end

  def draw(step=true)
    @mutex_draw.synchronize do
      drop_current_tile if step
      move_cursor()
      print "\e[1m" #boldify
      print @size[0].times.map{|y| @size[1].times.map do |x|
        block_to_str(@tile_current[[y,x].sub(@tile_current[:pos])] || @board[[y,x]] || EMPTY_CELL)
      end.join}.join("\r\n")
      print "\r\nnext:\r\n"
      print (@tile_next[:size][0]+1).times.map{|y| (@tile_next[:size][1]+1).times.map{|x| block_to_str(@tile_next[[y,x]] || EMPTY_CELL)}.join}.join("\r\n")
      print "\r\n\nScore: ", @score
      print "\r\n\mFPS: ", @fps
      STDOUT.flush
      @fps = fps()
    end
  end
  def input_handler(input)
    move = {
      "\e[A" => :rotate, #up
      "\e[B" => :down,
      "\e[D" => :left,
      "\e[C" => :right,
      ' '    => :drop,   #space
    }[input]
    case move
    when :down
      drop_current_tile(true)
    when :drop
      drop_current_tile(true, true)
    when :rotate
      tmp = @tile_current.dup
      @tile_current.rotate!
      @tile_current.rotate!
      @tile_current.rotate!
      @tile_current = tmp if current_tile_stuck
    when :left
      @tile_current[:pos][1] -= 1
      @tile_current[:pos][1] += 1 if current_tile_stuck
    when :right
      @tile_current[:pos][1] += 1
      @tile_current[:pos][1] -= 1 if current_tile_stuck
    end
    draw(false)
  end
end

if ARGV.include?('--help')
  puts 'tetrinal takes three optional parameters: [speedup] [size_y] [size_x]'
  puts '  speedup: there are 3 values: none, time and stepped. (default: stepped)'
  puts '  size_y: (default: 20)'
  puts '  size_x: (default: 9)'
  puts ''
  puts '--no-music           no music and sfx'
  puts '--random-tiles       randomly generate tiles'
  puts '--number-tiles       use number tiles (changes size to 30x40 if not given)'
  puts '--background=white   white background (default dark)'
  puts '--no-tiles-break     (default)'
  puts '--tiles-break=naive  tiles break if not connected (but can stick to walls on break)'
  puts '--tiles-break=full   tiles fall appart if nothing is below them'
  exit
end
opt = {}
opt[:random] = ARGV.delete('--random-tiles')
opt[:tiles_break] = :naive if ARGV.delete('--tiles-break=naive')
opt[:tiles_break] = :unless_supported if ARGV.delete('--tiles-break=full')
opt[:tiles_break] = false if ARGV.delete('--no-tiles-break')
Tetrinal::EMPTY_CELL[:symbol] = '⬜' if ARGV.delete('--background=white')
opt[:numbers] = ARGV.delete('--number-tiles')
opt[:speedup] = ARGV[0] if ARGV.length >= 1
if opt[:numbers] && ARGV.length <= 1
  opt[:size_y] = 30
  opt[:size_x] = 40
end
opt[:size_y] = ARGV[1].to_i if ARGV.length >= 2
opt[:size_x] = ARGV[2].to_i if ARGV.length >= 3
Tetrinal.new(**opt).run if __FILE__ == $PROGRAM_NAME
# highscore: 7129
