require_relative 'Field.rb'
require_relative 'Cell.rb'
require_relative 'Point.rb'

class Minesweeper
  def initialize size, mines
    @field = Field.new size, mines
    @counter = size**2 - mines
    gameloop
    @field.draw
    puts '>you win' if @counter == 0
  rescue Interrupt
    puts "\n>Goodbye"
  end

  def gameloop
    while @counter > 0
      @field.draw
      sweep
    end
  rescue BOOOM
    puts 'BOOOM'
  end

  def sweep
    point = Point.new STDIN.gets
    @counter -= @field.sweep point
  rescue InitFailed
    puts '>bad input'
    retry
  end
end

field_size = ARGV[0].to_i
num_mines = ARGV[1].to_i
raise 'More Mines than Fields' if num_mines >= field_size**2
Minesweeper.new field_size, num_mines
