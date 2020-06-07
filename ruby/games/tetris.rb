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


# Tetrinal
class Tetris < TerminalGame
  EMPTY_CELL = {symbol:' ', color: [255,255,255]}
  def initialize(size_x=9, size_y=20)
    @board = Hash.new
    @size = [size_y, size_x]
    @fps = 5
    @tile_current = gen_tile
    @tile_next = gen_tile
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
    elem[:pos] = [0,0]
    elem
  end

  def drop_current_tile(completely=false)
    begin
      @tile_current[:pos][0] += 1
      if @board.any?{|k,v| @tile_current[k.sub(@tile_current[:pos])] rescue false}
        @tile_current[:pos][0] -= 1
        next_tile
        return
      elsif @tile_current.any?{|k,v| k.is_a?(Array) ? (k.first + @tile_current[:pos][0]+1) >= @size[0] : false}
        @tile_current[:pos][0] -= 1
        next_tile
        return
      end
    end while completely
  end

  def next_tile
    @tile_current.each{|k,v| @board[k.add(@tile_current[:pos])] = v if k.is_a?(Array)}
    @tile_current = @tile_next
    @tile_next = gen_tile
    @board.group_by{|k,v| k.first}.select{|k,v| v.count == @size[1]}.each do |k,v|
      v.map{|x|@board.delete(x.first)}
    end
    raise "you lost" if @board.any?{|(y,x),v| y <= 0 }
  end

  def draw(step=true)
    move_cursor()
    clear()
    drop_current_tile if step
    print @size[0].times.map{|y| @size[1].times.map do |x|
      e = @board[[y,x]] || EMPTY_CELL
      tile = "#{get_color_code(e[:color])}#{e[:symbol]}#{get_color_code()}"
      droping_tile = @tile_current[[y,x].sub(@tile_current[:pos])]
      tile = "#{get_color_code(droping_tile[:color])}#{droping_tile[:symbol]}#{get_color_code()}" if droping_tile
      tile
    end.join }.join("\r\n")
    print "\r", '-' * @size[1]
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
    when :rotate
      @tile_current.rotate!
    when :down
      drop_current_tile
    when :left
      @tile_current[:pos][1] -= 1
    when :right
      @tile_current[:pos][1] += 1
    when :drop
      drop_current_tile(true)
    end
    draw(false)
  end
end

Tetris.new.run if __FILE__ == $PROGRAM_NAME
