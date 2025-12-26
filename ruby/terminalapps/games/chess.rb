require_relative '../lib/gamelib'

def draw
  field = []
  field << '♖♘♗♕♔♗♘♖'
  field << '♙♙♙♙♙♙♙♙'
  field << '        '
  field << '        '
  field << '        '
  field << '♟♟♟♟♟♟♟♟'
  field << '♜♞♝♛♚♝♞♜'
  field = field.each_with_index.map do |e,j|
    e.split('').each_with_index.map{|e,i| "#{TerminalGame.get_color_code(4, :bg) if (i+j)%2 == 0}#{e}#{TerminalGame.color_reset_code}"}.join('')
  end
  puts field
end

draw
