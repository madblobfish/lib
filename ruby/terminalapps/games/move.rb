require_relative '../lib/gamelib'
require_relative '../../stdlib/color_palette.rb' rescue nil

class Array
  def index2d(item)
    self.each_with_index{|arr, i| j = arr.index(item); return [i,j] if j}
    return
  end
  def swap2d(a,b)
    self[a[0]][a[1]], self[b[0]][b[1]] = self[b[0]][b[1]], self[a[0]][a[1]]
    self
  end
end

class Move < TerminalGame
  def initialize(size_x=4, size_y=4)
    @fps = :manual
    @size = [size_x -1, size_y -1]
    @map = (size_y*size_x).times.to_a.shuffle.each_slice(size_x).to_a
    @pos = @map.index2d(0)
    @moves = 0
  end

  def check_win
    flat = @map.flatten
    flat.delete(0)
    raise "win in #{@moves}" if flat == flat.sort
  end

  def draw
    check_win
    move_cursor
    print @map.map{|x| x.map{|n| n == 0 ? '  ' : "%2d" % n}.join(' ')}.join("\r\n")
  end

  def input_handler(input)
    prev_pos = @pos.dup
    case input
    when "\e[A" #up
      return if @pos[0] <= 0
      @pos[0] -= 1
    when "\e[B" #down
      return if @pos[0] >= @size[0]
      @pos[0] += 1
    when "\e[C" #right
      return if @pos[1] >= @size[1]
      @pos[1] += 1
    when "\e[D" #left
      return if @pos[1] <= 0
      @pos[1] -= 1
    else
      return
    end
    @moves += 1
    @map.swap2d(@pos, prev_pos)
    draw
  end
end

if __FILE__ == $PROGRAM_NAME
  Move.new().run()
end
