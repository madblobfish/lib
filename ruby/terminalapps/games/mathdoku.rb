class KenKenBoard
  OP_TO_S = {
    add: '+',
    sub: '-',
    mul: '*',
    div: '/',
    mod: '%',
    lds: 'lds',
    # nor: 'nor',
    xor: '⊻',
    none: '',
  }
  attr :size, :board_numbers, :board_groups, :group_meta
  def initialize(size, ops=OP_TO_S.keys)
    @operators_bounding_set = ops.dup
    @size = [size, 9].min
    @board_numbers = Array.new(@size){|i| Array.new(@size){|j| (i+j)%@size+1}}.shuffle.transpose.shuffle
    @board_groups = Array.new(@size){|i| Array.new(@size){-1}}
    current_group = 0
    @all_indexes = Array.new(@size*@size){|i| [(i/@size).to_i, i % @size]}
    @all_indexes.shuffle.each do |i,j|
      next unless @board_groups[i][j].negative?
      @board_groups[i][j] = current_group
      group_size = rand(0..3)
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
      ops -= [:none]
      if a.count == 2
        unless (a.max % a.min) == 0
          ops -= [:div]
        else
          ops += [:div]*3
        end
        ops += [:mod, :sub]*2
      else
        ops -= [:mod, :div, :sub]
      end
      ops &= @operators_bounding_set
      case ops.sample
      when :add
        [:add, a.sum]
      when :mul
        [:mul, a.reduce(1){|c,e|c*e}]
      when :sub
        [:sub, a.max - a.min]
      when :div
        [:div, a.max / a.min]
      when :mod
        [:mod, a.max % a.min]
      when :xor
        [:xor, a.reduce{|c,e| c^e}]
      when :lds
        [:lds, (lds = (a.sum+9) % 9) == 0 ? 9 : lds ]
      else
        raise 'AHHHH '+ ops.to_s
      end
    end
    STDERR.puts groups.count{|k,v| v.length == 1}
  end

  def _all_directions_matrix(i,j)
    [
      [i  ,j+1],
      [i  ,j-1],
      [i+1,j],
      [i-1,j],
    ]
  end
  def _all_directions_with_dir(i,j)
    _all_directions_matrix(i,j).zip(%w(right left bottom top))
  end
  def _random_walk_get_possible_steps(grps,i,j)
    _all_directions_matrix(i,j).reject{|a,b| a.negative? || b.negative? rescue true}.select{|a,b| grps[a][b].negative? rescue false}
  end

  def bold_vert
    @board_groups.map{|row| row.each_cons(2).map{|a,b| a==b}}
  end
  def bold_hori
    @board_groups.transpose.map{|row| row.each_cons(2).map{|a,b| a==b}}
  end
  def print
    answers = '𝟘𝟙𝟚𝟛𝟜𝟝𝟞𝟟𝟠𝟡'
    width = 7
    height = 3
    bold_vert = bold_vert()
    bold_hori = bold_hori()
    out = Array.new(@size)
    out[0] = '┏' + ('━' * width) + bold_vert.first.map{|b| (b ? '┳' : '┯') + ('━' * width)}.join('')+ '┓'
    @board_numbers.flatten.each_with_index.group_by{|x,i| idx=@all_indexes[i];}
    out
  end

  def to_html
    groups_already_drawn = []
    @board_numbers.each_with_index.map do |row, i|
      DATA.read + '<tr>' +
        row.each_with_index.map do |e, j|
          group = @board_groups[i][j]
          out = "<td style=\"#{
            _all_directions_with_dir(i,j).map{|(x,y),dir| group == @board_groups[x][y] ? "border-#{dir}-color:silver" : nil rescue nil }.compact.join('; ')
          }\"><div>#{
            [@group_meta[group]].map{|op, num| "#{num}#{OP_TO_S[op]}" }[0] unless groups_already_drawn[group]
          }</div><input name=#{i}#{j} size=1></td>"
          groups_already_drawn[group] = true
          out
        end.join("\n") + '</tr>'
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  require 'ostruct'
  os = OpenStruct.new
  os.field_size = 5
  os.field_size__short = "s"
  os.max_group_size = 5
  os.color = true
  os.color__short = "c"
  os.output = "bare"
  os.output__short = "o"
  os.output__values = %w(bare html interactive)
  os.output__help = 'one of: '+ os.output__values.join(', ')
  os.operators = KenKenBoard::OP_TO_S.keys
  os.operators__short = 'm'
  os.operators__proc = Proc.new{|v|v.map(&:to_sym)}
  os.operators__help = 'list of math operators, sparated by ,'

  begin
    require 'optsparser_generator'
    args = OptParseGen.parse!(os)
  rescue LoadError
    puts 'could not load "optsparser_generator" lib, can\'t parse options'
    args = os
  end

  kb = KenKenBoard.new(args.field_size, args.operators)
  case args.output
  when "bare"
    puts kb.board_numbers.map{|e| e.join(" ") }.join("\n"), "\n\n"
    puts kb.board_groups.map{|e| e.map{|e| "%02i" % e }.join(" ") }.join("\n")
    p kb.group_meta
    # p kb.print
  when "html"
    puts kb.to_html
    puts '<script> solution="'+kb.board_numbers.map{|e| e.join('')}.join('')+'"</script>'
  end
end

__END__
<!DOCTYPE html>
<html>
<head>
  <title></title>
  <style>
    .game{

    }
    table{
      border-collapse:collapse;
    }
    td{
      width: 60px;
      height: 60px;
      position: relative;
      border: 2px black solid;
    }
    td center{
      font-weight: 900;
      font-size: 16pt
    }
    pre{
      margin:0;
      bottom:0;
      right:0;
      position: absolute;
    }
    td div{
      position: absolute;
      top:0;
      left:0;
    }
    input{
      appearance: none;
      -moz-appearance: none;
      border: none;
      width:94%;
      height:94%;
      text-align:center;
      font-size:20pt;
    }
    input:focus{
      background:#aaa
    }
  </style>
  <script>
    document.addEventListener("keydown", (e)=>{
      if(e.target.nodeName == "INPUT"){
        where = e.target.name.split("").map((e)=>parseInt(e))
        mod = false
        switch(e.code){
          case "ArrowUp":
            mod = true
            where[0] = where[0]-1
            break;
          case "ArrowDown":
            mod = true
            where[0] = where[0]+1
            break;
          case "ArrowLeft":
            mod = true
            where[1] = where[1]-1
            break;
          case "ArrowRight":
            mod = true
            where[1] = where[1]+1
            break;
        }
        if(mod){
          document.querySelector(`input[name="${where.join('')}"]`).focus()
        }

      }
    })
    function clearWrong(){
      let n = Math.sqrt(solution.length)
      solution.split("").forEach((e, i)=>{
        let inp = document.querySelector('input[name="'+ ~~(i/n) +''+ (i%n) +'"]')
        if(inp.value != e && inp.value.length == 1){
          inp.value = ''
        }
      })
    }
  </script>
</head>
<body>

<dl>
  <dt>⊻</dt>
  <dd>XOR operator.</dd>
  <dt>lds</dt>
  <dd>Last Digit Sum = calculate digit sum till its one digit.</dd>
  <dt>Other operators (+ - * / %)</dt>
  <dd>Work as in Math, % is Modulo or the Remainder of a Division</dd>
</dl>
  <button href="#" onclick="document.querySelectorAll('input').forEach((x)=>x.value='')">CLEAR</button>
  <button href="#" onclick="clearWrong()">clear wrong solutions (only single letter fields)</button>
  <table colspan="0" class="game">
