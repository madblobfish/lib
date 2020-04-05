class KenKenBoard
  attr :size, :board_numbers, :board_groups, :group_meta
  def initialize(size, ops=[:add, :sub, :mul, :div, :mod, :lds])
    @size = [size, 9].min
    @board_numbers = Array.new(@size){|i| Array.new(@size){|j| (i+j)%@size+1}}.shuffle
    @board_groups = Array.new(@size){|i| Array.new(@size){-1}}
    current_group = 0
    @all_indexes = Array.new(@size*@size){|i| [(i/@size).to_i, i % @size]}
    @all_indexes.shuffle.each do |i,j|
      next unless @board_groups[i][j].negative?
      @board_groups[i][j] = current_group
      group_size = rand(0..5)
      current_pos = [i,j]
      group_size.times do
        current_pos = _random_walk_get_possible_steps(@board_groups, *current_pos).sample
        break if current_pos.nil?
        @board_groups[current_pos.first][current_pos.last] = current_group
      end
      current_group += 1
    end

    groups = @board_numbers.flatten.each_with_index.group_by{|x,i| idx=@all_indexes[i]; @board_groups[idx.first][idx.last]}.transform_values{|a|a.map(&:first)}
    @group_meta = groups.transform_values do |a|
      next [:none, a.first] if a.one?
      ops -= [:mod, :div, :sub] unless a.count == 2
      ops -= [:div] unless (a.min % a.max) == 0
      case ops.sample
      when :add
        [:add, a.sum]
      when :mul
        [:mul, a.reduce(1){|c,e|c*e}]
      when :sub
        [:sub, a.max - a.min]
      when :div
        [:div, a.min / a.max]
      when :mod
        [:mod, a.max % a.min]
      when :lds
        [:lds, (a.sum+9) % 9 ]
      end
    end
  end

  def _random_walk_get_possible_steps(grps,i,j)
    [
      [i  ,j+1],
      [i  ,j-1],
      [i+1,j],
      [i-1,j],
    ].reject{|a,b| a.negative? || b.negative? rescue true}.select{|a,b| grps[a][b].negative? rescue false}
  end

  def print
    answers = "𝟘𝟙𝟚𝟛𝟜𝟝𝟞𝟟𝟠𝟡"
    width = 7
    height = 3
    bold_vert = @board_groups.map{|row| row.each_cons(2).map{|a,b| a==b}}
    bold_hori = @board_groups.transpose.map{|row| row.each_cons(2).map{|a,b| a==b}}
    out = Array.new(@size)
    out[0] = "┏" + ("━" * width) + bold_vert.first.map{|b| (b ? "┳" : "┯") + ("━" * width)}.join('')+ "┓"
    @board_numbers.flatten.each_with_index.group_by{|x,i| idx=@all_indexes[i];}
    out
  end
end


kb = KenKenBoard.new(4)
puts kb.board_numbers.map{|e| e.join(" ") }.join("\n"), "\n\n"
puts kb.board_groups.map{|e| e.map{|e| "%02i" % e }.join(" ") }.join("\n")
p kb.group_meta
# p kb.print


__END__

┏━━━━━━━┯━━━━━━━┳┓
┃5+  123│       ┃
┃    456│       ┃
┃𝟙   789│𝟚      ┃
┣━━━━━━━╈━━━━━━━╋ ─
┗┛
┠ ┡ ┢ ┣ ┤ ┥ ┦ ┧ ┨ ┩ ┪ ┫ ┯ ┳ ┷ ┻
┼ ┽ ┾ ┿ ╀ ╁ ╂ ╃ ╄ ╅ ╆ ╇ ╈ ╉ ╊ ╋

https://en.wikipedia.org/wiki/Box-drawing_character
https://en.wikipedia.org/wiki/Blackboard_bold
1234
2341
3412
4123

