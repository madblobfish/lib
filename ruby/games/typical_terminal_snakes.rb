require_relative "lib/gamelib.rb"

class TTS < TerminalGame
  EMPTY_CELL = {symbol:'⬜', color: [50,50,50]}
  GOOD_FOOD = "🌽🍇🍈🍉🍊🍋🍌🍍🍎🍏🍐🍑🍒🍓🌰"
  BAD_FOOD = "🍄👟🔧📎📞💊💉"
  def initialize(size_x=9, size_y=9)
    @field = Hash.new{EMPTY_CELL}
    @size = [size_y, size_x]
    @current_pos = [size_y/2, size_x/2]
    @fps = 3
    @direction = [0, 1] # right
    @direction_of_last_step = [0, 1]
    @score = 0
    @len = 5
    food_stuff()
  end

  def food_stuff
    food_count = @field.count{|k,v| GOOD_FOOD.include?(v) rescue false}
    if food_count <= 0
      ((0...(@size[0])).to_a.product((0...(@size[1])).to_a) - [[1,0],[-1,0],[0,1],[0,-1]].map{|dir| calc_next_step(dir)})
        .shuffle.reject{|pos|@field.has_key?(pos)}.take(rand(1..4)).each do |pos|
          @field[pos] = (GOOD_FOOD + BAD_FOOD).split('').sample
      end

    end
  end

  def calc_next_step(dir=@direction_of_last_step, pos=@current_pos, size=@size)
    pos.zip(dir, size).map{|a,b,c| (a+b+c) % c }
    # next_pos = [
    #   (@current_pos[0] + @direction_of_last_step[0] + @size[0]) % @size[0],
    #   (@current_pos[1] + @direction_of_last_step[1] + @size[1]) % @size[1],
    # ]
  end

  def step
    @direction_of_last_step = @direction
    next_pos = calc_next_step()
    @field.transform_values!{|x| x.is_a?(Numeric) ? x-1 : x }
    @field.reject!{|k,v| v < 0 rescue false}
    if GOOD_FOOD.include?(@field[next_pos].to_s)
      @len += 1
      @score += 100
      @field.delete(next_pos)
    end
    raise "Ur ded (Score: #{@score})" if @field.has_key?(next_pos)
    @field[next_pos] = @len
    @current_pos = next_pos
  end

  def snake_color(n)
    require_relative '../stdlib/color_palette.rb'
    color_to_ansi(*color_palette(n.to_f / @len))
  rescue
    ""
  end

  def block_to_str(block)
    return "#{snake_color(block)}██#{get_color_code()}" if block.is_a?(Numeric)
    return block if block.is_a?(String)
    "#{get_color_code(block[:color])}#{block[:symbol]}#{get_color_code()}"
  end
  def draw
    step()
    food_stuff()
    move_cursor()
    print @size[0].times.map{|y| @size[1].times.map do |x|
      block_to_str(@field[[y,x]])
    end.join}.join("\r\n")
    print "\r\n\nScore:", @score
  end

  def input_handler(input)
    dir = {
      "\e[A" => [-1,0],
      "\e[B" => [ 1,0],
      "\e[D" => [0,-1],
      "\e[C" => [0, 1],
    }[input]
    return if dir.nil?
    @direction = dir unless dir == @direction_of_last_step.map{|x|x*-1}
  end
end

if __FILE__ == $PROGRAM_NAME
  TTS.new.run()
end
