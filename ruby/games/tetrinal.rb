require_relative 'lib/gamelib.rb'

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
  EMPTY_CELL = {symbol:' ', color: [255,255,255]}
  def initialize(size_x=9, size_y=20)
    @board = Hash.new
    @size = [size_y, size_x]
    @fps = 3
    @tile_current = gen_tile
    @tile_next = gen_tile
    @sync = false
    @score = 0
  end

  def gen_tile
    color = rand(9..14)
    elem = {}
    [
      "    \n    \n####    \n    ",
      "   \n###\n#  ",
      "   \n###\n  #",
      "   \n###\n # ",
      "##\n##",
      "  #\n ##\n # ",
      " # \n ##\n  #",
    ].sample.split("\n").each_with_index{|s,i| s.split('').each_with_index{|s,j| elem[[i,j]] = {symbol:'#', color: color} if s == '#'; elem[:size] = [i,j]}}
    rand(0..3).times{elem.rotate!}
    elem[:pos] = [-2, @size[1] / 2 -1]
    elem
  end

  def current_tile_stuck
    # stuck in other block
    return true if @board.any?{|k,v| @tile_current[k.sub(@tile_current[:pos])] rescue false}
    # stuck on ground
    return true if @tile_current.any?{|k,v| k.is_a?(Array) ? (k.first + @tile_current[:pos][0]+1) >= @size[0] : false}
    # stuck left
    return true if @tile_current.any?{|k,v| k.is_a?(Array) ? (k.add(@tile_current[:pos])[1]) < 0 : false}
    # stuck right
    return true if @tile_current.any?{|k,v| k.is_a?(Array) ? (k.add(@tile_current[:pos])[1]) >= @size[1] : false}
    false
  end

  def drop_current_tile(completely=false)
    begin
      @tile_current[:pos][0] += 1
      if current_tile_stuck
        @tile_current[:pos][0] -= 1
        next_tile
        return
      end
    end while completely
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
    end.each{|ymax| @board.transform_keys!{|y,x| [y <= ymax ? y+1 : y, x]}}
    @score += rows_removed
    @score += 5 if rows_removed == 4
    raise "you lost" if @board.any?{|(y,x),v| y <= 0 }
  end

  def draw(step=true)
    drop_current_tile if step
    move_cursor()
    print "\e[1m" #boldify
    print "\r", '-' * @size[1], "\r\n"
    print @size[0].times.map{|y| @size[1].times.map do |x|
      e = @board[[y,x]] || EMPTY_CELL
      tile = "#{get_color_code(e[:color])}#{e[:symbol]}#{get_color_code()}"
      droping_tile = @tile_current[[y,x].sub(@tile_current[:pos])]
      tile = "#{get_color_code(droping_tile[:color])}#{droping_tile[:symbol]}#{get_color_code()}" if droping_tile
      tile
    end.join }.join("\r\n")
    print "\r", '-' * @size[1]
    STDOUT.flush
  end
  def input_handler(input)
    move = {
      "\e[A" => :rotate, #up
      "\e[B" => :down,
      "\e[D" => :left,
      "\e[C" => :right,
      " "    => :drop,   #space
    }[input]
    return if move.nil?
    case move
    when :down
      drop_current_tile
    when :drop
      drop_current_tile(true)
    when :rotate
      tmp = @tile_current.dup
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

Tetrinal.new.run if __FILE__ == $PROGRAM_NAME
