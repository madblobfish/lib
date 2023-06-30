require_relative '../lib/gamelib'
require_relative '../../stdlib/color_palette.rb' rescue nil

class Maze < TerminalGame
  def initialize(size_x=70, size_y=16, death=false)
    @fps = :manual
    @size = [size_y, size_x]
    # @player = @size.map{|x|rand(x)}
    @player = @size.dup
    @path = [@player.dup]
    # @goal = [0,0]
    # @goal = @size.map{|x|rand(x)}
    # @goal = @size.map{|x|rand(x)} if @goal == @player
    @map = maze_gen_bt(@size)
    @goal = @map[:start]
    @start_time = Time.now
    @backwalk = 0
    @miswalk = 0
    @steps = 0
    @death = death
  end

  def maze_gen_bt(size=[70,16])
    GC.disable # more speed
    door_open_ud = Hash.new{false}
    door_open_lr = Hash.new{false}
    walked = Hash.new{false}
    free_fields = (size[0]+1) * (size[1]+1)

    path = [size.map{|x|rand((x+1)/2)}]
    start = path[0].dup
    walked[path[0].dup] = false

    while free_fields > 0 && path.any?
      pos = path.last
      moves = [[-1,0],[1,0],[0,1],[0,-1]].reject do |x,y|
        next_pos = [pos[0]+x, pos[1]+y]
        next_pos.any?(&:negative?) ||
          next_pos.zip(size).any?{|a,b|a>b} ||
          walked.has_key?(next_pos)
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
        walked[new_pos.dup] = false #path.length
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
    {ud:door_open_ud, lr:door_open_lr, start:start}
  end

  def die(text='won')
    raise <<~bla
      #{text}
      Miswalk: #{@miswalk}
      Backwalk: #{@backwalk}
      Steps: #{@steps}
      Path: #{@path.length}
      Time: #{Time.now - @start_time}s"
    bla
  end
  def check_win
    die if @goal == @player
  end

  def initial_draw
    print get_color_code(15, :fg)
    sync_draw{draw()}
  end
  def draw
    check_win()
    move_cursor
    print ' Miswalk: ', @miswalk unless @death
    print ' Backwalk: ', @backwalk
    print ' Steps: ', @steps
    print ' Path: ', @path.length
    print ' Time: ', Time.now - @start_time
    puts "s\r"
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
          if [x,y/2] == @goal
            print get_color_code(color_palette(0.5), :fg), '╬', get_color_code(15, :fg)
          elsif player_loc
            print get_color_code(color_palette(1),:bg), ' ', get_color_code(0,:bg)
          else
            print marker
          end
          print @map[:lr][[x, y/2]] ? (@path.index([x+1,y/2]) ? marker : ' ') : '█'
        else
          print @map[:ud][[x, y/2]] ? (@path.index([x,(y+1)/2]) ? marker : ' ') : '█'
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
    @steps += 1
    old_pos = @player.dup
    @player[0] += dir[0]
    @player[1] += dir[1]
    if @path.last == old_pos && @path[-2] == @player
      @backwalk += 1
      @path.pop
      sync_draw{draw()}
      return
    end
    door_open = if dir[1] == 0
        @map[:lr][[@player, old_pos].min]
      else
        @map[:ud][[@player, old_pos].min]
      end
    unless door_open
      die('LOOOSER!') if @death
      @miswalk += 1
      @player = old_pos
      sync_draw{draw()}
      return
    end
    @path.push(@player.dup)
    sync_draw{draw()}
  end
end

if __FILE__ == $PROGRAM_NAME
  deth = ARGV.delete('--death') ? true : false
  case ARGV.first
  when 'eazy'
    Maze.new(7,13,deth).run()
    # Miswalk: 0
    # Backwalk: 0
    # Steps: 23
    # Path: 24
    # Time: 7.520582832s
  when 'normal'
    Maze.new(10,16,deth).run()
    # Miswalk: 0
    # Backwalk: 0
    # Steps: 93
    # Path: 84
    # Time: 21.404004426s
  when 'har'
    Maze.new(15,40,deth).run()
    # Miswalk: 0
    # Backwalk: 39
    # Steps: 255
    # Path: 178
    # Time: 88.105600061s
  when 'hard'
    Maze.new(28,100,deth).run()
    # Miswalk: 109
    # Backwalk: 218
    # Steps: 1918
    # Path: 1374
    # Time: 1937.503126671s
  else
    puts 'hi we got 4 modi [hard|har|normal|eazy]'
    puts 'try --death for more fun'
  end
end
