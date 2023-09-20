require_relative '../lib/gamelib.rb'
class Pong < TerminalGame
  def initialize(**opts)
    @board = Hash.new
    @size = [opts.fetch(:size_x, 30), opts.fetch(:size_y, 10)]
    @paddle_size = 3
    @player_a = @size[1]/2 - @paddle_size/2
    @player_b = @player_a
    @fps = 4
    @ball = @size.map{|x| x/2.0}
    @ball_dir = 0
    @score = 0
  end

  def move_ball
    @ball = [
      Math.cos(@ball_dir*Math::PI)*1,
      Math.sin(@ball_dir*Math::PI)*1,
    ]
  end

  def draw(step=true)
    move_ball if step
    move_cursor()
    print @size[1].times.map{|y| @size[0].times.map do |x|
      if @ball.map(&:to_i) == [x,y]
        'X'
      elsif x == 1 && @player_a.upto(@player_a + @paddle_size).include?(y)
        # left
        'O'
      elsif x == @size[0] - 1 && @player_b.upto(@player_b + @paddle_size).include?(y)
        # player/right
        '§'
      else
        ' '
      end
    end.join}.join("\r\n")
    STDOUT.flush
  end
  def input_handler(input)
    case input
    when "\e[A"
      @player_b -= 1
    when "\e[B"
      @player_b += 1
    end
    draw(false)
  end
end

if ARGV.include?('--help')
  puts 'pong, you know, the paddle game'
  exit
end

Pong.new().run if __FILE__ == $PROGRAM_NAME
