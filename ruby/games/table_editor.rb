require_relative 'lib/gamelib'
require 'csv'

class TableEditor < TerminalGame
  def initialize()
    @draw_borders = true

    @fps = :manual
    @pos = [0,0]
    @file = ARGV.first if ARGV.one?
    if File.readable?(@file)
      @edited = false
      @table = CSV.read(@file, col_sep: ';')
    else
      @edited = true
      @table = [[' ']]
    end
    @cell_pos = :override
  end

  def draw
    move_cursor
    clear
    size = @table.transpose.map{|c| c.map(&:length).max}
    row_separator = size.map{|e| '─'*e }.join('┼') + "┤\r\n"
    @table.each_with_index do |line, y|
      raise size.inspect if line.first == 'Login emailxxxxxx'
      print line.each_with_index.map{|elem, x|
        @pos == [x,y] ? color_invert_code+(
          @cell_pos == :override ? elem.ljust(size[x]) : elem.ljust(size[x]).insert([@cell_pos+1,size[x]].min, color_invert_code).insert(@cell_pos, color_reset_code)
        )+color_reset_code : elem.ljust(size[x])
      }.join('│')
      print "│\r\n"
      print row_separator
    end
    print color_invert_code unless @cell_pos == :override
    print @pos.inspect + color_reset_code
  end

  def game_quit
    kill_threads
    clear;move_cursor
    return unless @edited
    print "unsaved changes, Save? [yN]"
    if %w(y Y).include?(STDIN.read(1))
      reset_tty_state
      if @file.nil?
        clear;move_cursor
        print "save as: "
        @file = STDIN.readline.strip
      end
      File.write(
        @file,
        CSV.generate(col_sep: ';'){|c| @table.each{|l| c << l}}
      )
    end
  end

  def delete_right
    @edited = true
    @table.map(&:pop)
  end
  def delete_down
    @edited = true
    @table.pop
  end
  def expand_right
    @edited = true
    @table.map!{|l|l << ' '}
  end
  def expand_down
    @edited = true
    @table << Array.new(@table.first.length){' '}
  end

  def input_handler(input)
    # prev_pos = @pos.dup
    handled = true
    if @cell_pos == :override
      case input
      when "\e[D", "\x1b[Z" #left
        return if @pos[0] <= 0
        @pos[0] -= 1
        @cell_pos = :override
      when "\e[C" #right
        return if @pos[0] >= @table.first.length - 1
        @pos[0] += 1
        @cell_pos = :override
      else
        handled = false
      end
    else # edit "mode"
      case input
      when "\r" #enter
        expand_down if @pos[1] >= @table.length - 1
        @pos[1] += 1
        @cell_pos = :override
      else
        handled = false
      end
    end
    if handled
      draw
      return
    end
    case input
    when "\x1b[1;5A" #delete up
      delete_down
      @pos[1] -= 1 if @pos[1] >= @table.length
    when "\x1b[1;5D" #delete right
      delete_right
      @pos[0] -= 1 if @pos[0] >= @table.first.length
    when "\x1b[1;5C" #new right
      expand_right
      @pos[0] += 1
    when "\x1b[1;5B" #new down
      expand_down
      @pos[1] += 1
    when "\e[A" #up
      return if @pos[1] <= 0
      @pos[1] -= 1
      @cell_pos = :override
    when "\e[B" #down
      return if @pos[1] >= @table.length - 1
      @pos[1] += 1
      @cell_pos = :override
    when "\e[C" #right
      @cell_pos += 1 unless @cell_pos > (@table[@pos[1]][@pos[0]].length - 1)
    when "\e[D" #left
      @cell_pos -= 1 unless @cell_pos <= 0
    when "\x1b" #escape
      @cell_pos = :override
    when "\x1bOH", "\x1b[H" #pos1
      @cell_pos = 0
    when "\r", "\x1bOF", "\x1b[F" #enter, ende
      @cell_pos = @table[@pos[1]][@pos[0]].length
    when "\t" #tab
      if @pos[0] >= @table.first.length - 1
        @pos[0] = 0
        expand_down if @pos[1] >= @table.length - 1
        @pos[1] += 1
      else
        @pos[0] += 1
      end
      @cell_pos = :override
    when "\x1b[3~" #entf
      @edited = true
      @table[@pos[1]][@pos[0]][@cell_pos] = ''
    when "\x7f" #backspace
      @edited = true
      @table[@pos[1]][@pos[0]][@cell_pos-1] = '' if @cell_pos > 0
      @cell_pos -= 1
      @cell_pos = 0 if @cell_pos < 0
    when /\A[a-zA-Z0-9 _,.;:()?!"§$%&\\\/=-]\z/ #typing
      @edited = true
      if @cell_pos == :override
        @cell_pos = 1
        @table[@pos[1]][@pos[0]] = input
      else
        @table[@pos[1]][@pos[0]].insert(@cell_pos, input)
        @cell_pos += 1
      end
    else
      return
    end
    draw
  end
end

TableEditor.new().run() if __FILE__ == $PROGRAM_NAME
p "│─┼"
