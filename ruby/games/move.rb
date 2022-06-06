require_relative 'lib/gamelib'
require_relative '../stdlib/color_palette.rb' rescue nil

class Move < TerminalGame
  def initialize(size_x=10, size_y=10)
    @size = [size_y, size_x]
    @map = (size_y*size_x -1).times.shuffle
    @pos = 
  end

  def draw
    check_win()
    move_cursor
  end

  def input_handler(input)
    dir = {
      "\e[A" => [0,-1],
      "\e[B" => [0, 1],
      "\e[D" => [-1,0],
      "\e[C" => [ 1,0],
    }[input]
    return if dir.nil?
  end
end

if __FILE__ == $PROGRAM_NAME
  Move.new().run()
end
