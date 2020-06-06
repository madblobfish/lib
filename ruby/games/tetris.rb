require_relative 'lib/gamelib.rb'

class Array
  def rotate_clock
    self.transpose.map(&:reverse)
  end
  def at
  end
end

# Tetrinal
class Tetris < TerminalGame
  EMPTY_CELL = {symbol:' ', color: [255,255,255]}
  def initialize(size_x=9, size_y=20)
    @board = Array.new(size_y){Array.new(size_x){EMPTY_CELL.dup}}
    @fps = 1
    @tile_current = gen_tile
    @tile_current_pos = [0, 0]
    @tile_next = gen_tile
  end

  def gen_tile
    color = (9..14).to_a.sample
    elem = [
      '####',
      "###\n#  ",
      "###\n  #",
      "###\n # ",
      "##\n##",
      " #\n##\n# ",
      "# \n##\n #",
    ].sample.split("\n").map{|e| e.split('').map{|e|
      case e
      when ' '
        EMPTY_CELL.dup
      when '#'
        {symbol:'#', color: color}
      end
    }}
    (0..3).to_a.sample.times{elem = elem.rotate_clock}
    elem
  end

  def drop_current_tile

  end

  def draw(step=true)
    move_cursor()
    clear()
    drop_current_tile if step
    print @board.each_with_index.map{|e, y| e.each_with_index.map do |e, x|
      tile = "#{get_color_code(e[:color])}#{e[:symbol]}#{get_color_code()}"
      droping_tile = @tile_current.fetch(x - @tile_current_pos.first, nil)&.fetch(y - @tile_current_pos.last, nil)
      tile = "#{get_color_code(droping_tile[:color])}#{droping_tile[:symbol]}#{get_color_code()}" if droping_tile
    end.join }.join("\r\n")
    print "\r", '-' * @board.first.length
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
      @tile_current = @tile_current.rotate_clock
    when :down
      drop_current_tile
    when :left
      @tile_current_pos[0] -= 1
    when :right
      @tile_current_pos[0] += 1
    when :drop
    end
    draw(false)
  end
end

Tetris.new.run if __FILE__ == $PROGRAM_NAME
