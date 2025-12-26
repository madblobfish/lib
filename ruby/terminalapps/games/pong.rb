require_relative '../lib/gamelib.rb'
require 'matrix'
class Pong < TerminalGame
  def initialize(**opts)
    @board = Hash.new
    @size = [opts.fetch(:size_x, 30), opts.fetch(:size_y, 10)]
    @paddle_size = opts.fetch(:paddle_size, 30)
    @player_a = @size[1]/2 - @paddle_size/2
    @player_b = @player_a
    @fps = 7
    @fps_start = 6
    @start = Time.now()
    @ball = @size.map{|x| x/2.0}
    @ball_dir = Vector[rand()+0.25, (rand()-0.5)].normalize
    # @ball_dir = rand()*Math::PI/2 + Math::PI/6 # between 15 and 60°
    @score = 0
  end

  def respawn(collision_dir)
    @ball_dir
  end
  def move_ball
    old_ball = @ball
    @ball = @ball.zip(@ball_dir.to_a).map{|a,b| a+b }

    if @ball[0] <= 0 # left side
      raise TerminalGameEnd, 'a died'
    elsif @ball[0] <= 2 # left side
      if @player_a.upto(@player_a + @paddle_size).include?(@ball[1].to_i)
        @ball_dir[0] *= -1
      end
    elsif @ball[0] >= @size[0] # right side
      raise TerminalGameEnd, 'b died'
    elsif @ball[0] >= @size[0]-2 # right side
      if @player_b.upto(@player_b + @paddle_size).include?(@ball[1].to_i)
        @ball_dir[0] *= -1
      end
    elsif @ball[1] <= 0 || @ball[1] >= @size[1]-1 # top & bottom
      @ball_dir[1] *= -1
    end
  end

  def draw(step=true)
    move_ball if step
    move_cursor()
    print '-'*@size[0] + "\r\n"
    print @size[1].times.map{|y| @size[0].times.map do |x|
      if @ball.map(&:to_i) == [x,y]
        'O'
      elsif x == 0 && @player_a.upto(@player_a + @paddle_size).include?(y)
        # left
        '█'
      elsif x == @size[0] - 1 && @player_b.upto(@player_b + @paddle_size).include?(y)
        # player/right
        '█'
      else
        ' '
      end
    end.join}.join("\r\n")
    print("\r\n")
    print '-'*@size[0] + "\r\n"
    # @score += 1
    STDOUT.flush
    @fps = @fps_start + Math.log(Time.now() - @start + 0.01)
  end
  def input_handler(input)
    case input
    when "\e[A"
      @player_b -= 1 unless @player_b <= 0
    when "\e[B"
      @player_b += 1 unless @player_b >= (@size[1] - @paddle_size - 1)
    when "w"
      @player_a -= 1 unless @player_a <= 0
    when "s"
      @player_a += 1 unless @player_a >= (@size[1] - @paddle_size - 1)
    end
    draw(false)
  end
end

if ARGV.include?('--help')
  puts 'pong, you know, the paddle game'
  puts ''
  puts 'ordered parameters:'
  puts '  size x:      defaults to 70'
  puts '  size y:      defaults to 70'
  puts '  paddle size: defaults to 4'
  exit
end
opts = {}
opts[:size_x] = ARGV.fetch(0, '70').to_i
opts[:size_y] = ARGV.fetch(1, '20').to_i
opts[:paddle_size] = ARGV.fetch(2, '4').to_i

Pong.new(**opts).run if __FILE__ == $PROGRAM_NAME
