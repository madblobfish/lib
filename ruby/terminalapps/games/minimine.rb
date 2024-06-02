require_relative '../lib/gamelib.rb'
require_relative '../../stdlib/color_palette.rb' rescue nil

class Minesweep < TerminalGame
  def initialize(size=12, mines=20)
    @map = Hash.new
    @map.default, @first_click, @mouse_support = ['#', true, true]
    @size, @mines = [size, mines].map{|e|Integer(e)}
  end
  def draw
    move_cursor
    print @size.times.map{|y|@size.times.map{|x|{'*'=>'#', '*!'=>'X'}.fetch(@map[[y,x]],@map[[y,x]])}.join}.join("\r\n")
    print "\r\nMines left: #{(@mines - @map.count{|k,v|%w(*! X).include?(v)}).to_s.rjust(@mines.to_s.length)}"
  end
  def mouse_handler(x, y, button_id, dir)
    return if dir != :up
    pos = [y, x]
    return draw if pos.any?{|c|c < 0 || c >= @size}
    if button_id == 0 # left click
      if @first_click
        @first_click = false
        (@size.times.to_a.product(@size.times.to_a) - [pos]).shuffle.take(@mines).each{|x,y|@map[[x,y]] = '*'}
      end
      raise TerminalGameEnd, 'ur ded' if @map[pos] == '*'
      uncover(*pos) if @map[pos] == '#'
    end
    @map[pos] = {'#'=>'X', '*'=>'*!', 'X'=>'#', '*!'=>'*'}.fetch(@map[pos], @map[pos]) if button_id == 2 # right click
    draw()
    raise TerminalGameEnd, 'win' if @map.none?{|k,v|%w(# * X).include?(v)}
  end
  def uncover(x,y)
    around = ((a=[-1,0,1]).product(a)-[0,0]).map{|a,b|[x+a, y+b]}.reject{|pos|pos.any?{|c|c<0 || c >= @size}}
    c = around.count{|pos|'*!'.include?(@map[pos])}
    @map[[x,y]] = "#{get_color_code(color_palette(c.to_f/8))}#{c}#{get_color_code}" rescue '0'
    (@map[[x,y]] = '·'; around.each{|pos|uncover(*pos) if %w(# X).include?(@map[pos])}) if c == 0
  end
end

Minesweep.new(*(ARGV + [12,20]).take(2)).run if __FILE__ == $PROGRAM_NAME
