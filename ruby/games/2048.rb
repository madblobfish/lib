require_relative 'lib/gamelib.rb'

class FourThousandFourtyEightError < StandardError;end
class GameOver < FourThousandFourtyEightError;end
class GameWin < FourThousandFourtyEightError;end
class InvalidMove < FourThousandFourtyEightError;end
class ImplementationError < FourThousandFourtyEightError;end

class FourThousandFourtyEight < TerminalGame
  attr :field, :size, :win_num
  def initialize(size = 4, win_num = 8192, **opts)
    @fps = :manual
    @opts = opts.dup
    @size = size
    @win_num = win_num
    @field = Array.new(size){Array.new(size){rand >= 0.9 ? 2 : 0}}
  end
  def initialize_dup(other)
    @field = @field.map{|e| e.dup }
  end

  def to_s
    num_size = @field.flatten.max.to_s.length
    out = ["\r┏"+ '━'*num_size + ('┳'+ '━' *num_size)* (@size-1) + '┓']
    out += [field.map do |row|
          '┃' + row.map{|e| FourThousandFourtyEight.beautify_num(e, num_size, @win_num, @opts[:color]) }.join('┃') + '┃'
        end.join("\r\n┣" + '━'*num_size + ('╋' + '━'*num_size) * (@size-1) + "┫\r\n")]
    out += ['┗' + '━'*num_size + ('┻' +'━'*num_size) * (@size-1) + '┛']
    out.join("\r\n")
  end
  def self.beautify_num(num, rjust, max_num = 8192, color = false)
    out = num.to_s.each_char.map{|e| "𝟘𝟙𝟚𝟛𝟜𝟝𝟞𝟟𝟠𝟡"[e.to_i] }.join('').rjust(rjust)
    if color
      begin
        require_relative '../stdlib/color_palette.rb'
      rescue LoadError => e
        return out
      end
      step = Math.log2((num+2)) / Math.log2(max_num*2)
      step = 0 if step == -Float::INFINITY
      out = color_to_ansi(*color_palette(step)) + out + "\x1b[0m"
    end
    out
  end

  def move(dir, check = true)
    raise InvalidMove, "AH" unless %i(up down right left).include?(dir)
    bla = lambda{|x| FourThousandFourtyEight.move_row_left(x, lambda{new_number()})}
    case dir
    when :left
      @field.map!{|row| bla.call(row)}
    when :right
      @field.map!{|row| bla.call(row.reverse).reverse}
    when :up
      @field = @field.transpose.map{|row| bla.call(row)}.transpose
    when :down
      @field = @field.transpose.map{|row| bla.call(row.reverse).reverse}.transpose
    end
    if check
      raise GameOver, "you loose" if loose?
      raise GameWin, "you win" if field.flatten.include?(@win_num)
    end
    self
  end

  def loose?
    (%i(up down right left).map{|dir| dup.move(dir, false).field} + [self.field]).uniq.length == 1
  end

  def new_number
    highest = (@field.flatten+[2]).max
    Array.new(20){|x|[*[0,0]*(x+1),2**(x+1)]}.flatten.reverse.drop_while{|x| x!=highest}.sample
  end
  def self.move_row_left(array, new_number = lambda{0})
    out = []
    pos = 0
    merge = true
    while true
      if array[pos] == 0
        merge = false
        pos += 1
        next
      end
      case array[pos+1]
      when nil
        out << array[pos] unless array[pos].nil?
        break
      when array[pos]
        if merge
          out << (array[pos])*2
          pos +=1
        else
          out << array[pos]
        end
      else
        out << array[pos]
      end
      pos += 1
    end
    out + Array.new(array.length - out.length){new_number.call()}
  end

  def initial_draw
    puts(self.to_s)
    puts
    puts "\rthis is a really bad clone of 2048"
    puts "\rHow to play? Press an arrow key."
  end
  def draw
#    clear
    move_cursor
    puts(self.to_s)
  end

  def input_handler(string)
    moves = {
      "\e[A" => :up,
      "\e[B" => :down,
      "\e[C" => :right,
      "\e[D" => :left,
    }
    move(moves[string])
    draw
  end
end

##
# Tests
raise ImplementationError, "ASDHG!" unless FourThousandFourtyEight.move_row_left([2,2]) == [4,0]
raise ImplementationError, "ASDHG!" unless FourThousandFourtyEight.move_row_left([2,2,0]) == [4,0,0]
raise ImplementationError, "ASDHG!" unless FourThousandFourtyEight.move_row_left([2,2,2]) == [4,2,0]
raise ImplementationError, "ASDHG!" unless FourThousandFourtyEight.move_row_left([2,2,4]) == [4,4,0]
raise ImplementationError, "ASDHG!" unless FourThousandFourtyEight.move_row_left([0,0,2,2]) == [2,2,0,0]
raise ImplementationError, "ASDHG!" unless FourThousandFourtyEight.move_row_left([2,2,0,2,2]) == [4,2,2,0,0]
raise ImplementationError, "ASDHG!" unless FourThousandFourtyEight.move_row_left([2,0,2]) == [2,2,0]
raise ImplementationError, "ASDH" unless (a = FourThousandFourtyEight.new).dup != a.move(:left).field

if __FILE__ == $PROGRAM_NAME
  require 'ostruct'
  os = OpenStruct.new
  os.field_size = 4
  os.field_size__short = "s"
  os.win_number = 2048
  os.win_number__short = "m"
  os.color = true
  os.color__short = "c"
  os.terminal_magic = false
  os.skip_intro = false
  begin
    require 'optsparser_generator'
    args = OptParseGen.parse!(os)
  rescue LoadError
    puts 'could not load "optsparser_generator" lib, can\'t parse options'
    args = os
  end

  FourThousandFourtyEight.new(args.field_size, args.win_number, **args.to_h).run
end
