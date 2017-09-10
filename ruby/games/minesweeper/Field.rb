class Field
  def initialize size, number_mines
    @field = Array.new2 size, &Cell.method(:new)

    numbers = [*(0...size**2)].sample number_mines
    numbers.each{ |number|
      @field[number / size][number % size] = Cell.new '+'
    }
  end

  def draw
    @field.each{ |line|
      line.each &:p
      puts
    }
  end

  def sweep point
    field_dup = @field.dup.freeze
    cell = point.cell_from_field field_dup
    cell.sweep point, self
  end

  def reduce_surround point
    field_dup = @field.dup.freeze
    point.each_around{ |p|
      [p.cell_from_field(field_dup), p] rescue nil
    }.reduce(0){ |a,b|yield a,b rescue a}
  end
end

def Array.new2 s
  new(s){
    new(s){yield}
  }
end
