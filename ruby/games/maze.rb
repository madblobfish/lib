require_relative 'lib/gamelib'
require_relative '../stdlib/color_palette.rb' rescue nil

class Maze < TerminalGame
  def initialize(size_x=70, size_y=16)
    @fps = :manual
    @size = [size_y, size_x]
    @player = @size.map{|x|rand(x)}
    @path = [@player.dup]
    @map = maze_gen_bt(@size)
  end
  def maze_gen_bt(size=[70,16])
    GC.disable # more speed
    door_open_ud = Hash.new{false}
    door_open_lr = Hash.new{false}
    walked = Hash.new{false}
    free_fields = (size[0]+1) * (size[1]+1)

    path = [size.map{|x|rand(x)}]
    start = path[0].dup
    walked[path[0].dup] = true

    while free_fields > 0 && path.any?
      pos = path.last
      moves = [[-1,0],[1,0],[0,1],[0,-1]].reject do |x,y|
        next_pos = [pos[0]+x, pos[1]+y]
        next_pos.any?(&:negative?) ||
          next_pos.zip(size).any?{|a,b|a>b} ||
          walked[next_pos] == true
      end
      if moves.any?
        move = moves.sample
        new_pos = pos.dup
        new_pos[0] += move[0]
        new_pos[1] += move[1]
        if move[1] == 0
          door_open_lr[[pos, new_pos].min] = true
        else
          door_open_ud[[pos, new_pos].min] = true
        end
        walked[new_pos.dup] = true
        free_fields -=1
        path.push(new_pos.dup)
      else
        if path.none?
          break
        end
        path.pop
      end
    end
    GC.enable
    {ud:door_open_ud, lr:door_open_lr}
  end

  def draw
    move_cursor
    puts '██' * (@size.first+2)
    print "\r"
    (@size.last*2+1).times.each do |y|
      print '█'
      (@size.first+1).times.each do |x|
        marker = if idx = @path.index([x,y/2])
            color_to_ansi(*color_palette(idx.to_f/@path.length)) +'█'+ get_color_code()
          else
            ' '
          end
        player_loc = [x,y/2] == @player
        if y.even?
          if player_loc
            print get_color_code(color_palette(1),:bg), 'X', get_color_code(0,:bg)
          else
            print marker
          end
          print @map[:lr][[x, y/2]] ? (player_loc ? ' ' : marker) : '█'
        else
          print @map[:ud][[x, y/2]] ? (player_loc ? ' ' : marker) : '█'
          print '█'
        end
      end
      print "█\r\n"
    end
    puts '██' * (@size.first+2)
  end

  def input_handler(input)
    dir = {
      "\e[A" => [0,-1],
      "\e[B" => [0, 1],
      "\e[D" => [-1,0],
      "\e[C" => [ 1,0],
    }[input]
    return if dir.nil?
    old_pos = @player.dup
    @player[0] += dir[0]
    @player[1] += dir[1]
    if @path.last == old_pos && @path[-2] == @player
      @path.pop
      draw()
      return
    end
    door_open = if dir[1] == 0
        @map[:lr][[@player, old_pos].min]
      else
        @map[:ud][[@player, old_pos].min]
      end
    unless door_open
      @player = old_pos
      draw()
      return
    end
    @path.push(@player.dup)
    draw()
  end
end

Maze.new(10,16).run()
