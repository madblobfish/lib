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
      "###\n#",
      "###\n  #",
      "###\n #",
      "##\n##",
      " #\n##\n#",
      "#\n##\n #",
    ].sample.split("\n").map{|e| e.split('').map{|e|
      case e
      when ' '
        EMPTY_CELL.dup
      when '#'
        {symbol:'#', color: color}
      end
    }}
    p elem
    (0..3).to_a.sample.times{elem = elem.transpose.map(&:reverse)}
  end
  def draw(step=true)
    move_cursor()
    print @board.map{|e| e.map{|e| "#{get_color_code(e[:color])}#{e[:symbol]}#{get_color_code()}" }.join }.join("\r\n")
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
    draw(false)
  end
end

Tetris.new.run if __FILE__ == $PROGRAM_NAME
