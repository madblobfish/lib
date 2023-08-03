class YAMLite
rule
  # root
  target: list EOF | dict EOF | eof

  eof: EOF | NEWLINE EOF

  dict: dict_entry | dict_entry dict { result = val[0].merge(val[1]) }
  dict_entry: dict_key ':' value { result = Hash[[[val[0], val[2]]]] }
  dict_key: DICT_KEY | DICT_KEY SPACE

  list: list_entry | list_entry list { val[1].unshift(val[0]); result = val[1] }
  list_entry: '-' value { result = [val[1]] }
    | '-' SPACE dict_key ':' newline INDENT INDENT dict DEDENT dict DEDENT {
      outer = Hash[[[val[2], val[7]]]]
      result = [val[9].merge(outer)]
    }
    | '-' SPACE dict_key ':' newline INDENT INDENT list DEDENT dict DEDENT {
      outer = Hash[[[val[2], val[7]]]]
      result = [val[9].merge(outer)]
    }
    | '-' SPACE dict_key ':' simple_value INDENT dict DEDENT { result = [val[6].merge(Hash[[[val[2], val[4]]]])] }

  simple_value: SPACE BOOL newline { result = val[1] }
    | SPACE NUMBER newline { result = val[1] }
    | SPACE STRING newline { result = val[1] }
  value: simple_value
    | newline INDENT list DEDENT { result = val[2] }
    | newline INDENT dict DEDENT { result = val[2] }

  newline: NEWLINE | NEWLINE newline

end

---- header
# Experimental strict parser for a subset of yaml
#
# generated using: racc yamlite.y -o yamlite.rb
# $debug = true
---- inner
  def emit_indent()

  end
  def parse(str)
    @q = []
    row = 1
    column = 0
    start_of_file = true
    indent_type = nil
    indent_string = ''
    indent_level = 0
    until str.empty?
      case str
      when start_of_file && /\A---/
        row += 1
        # ignore
      when (@q.last || []).first != :INDENT && /\A #[^\n]+/
        # inline comment, ignore
      when (@q.last || []).first == :INDENT && /\A#[^\n]+/
        # comment, ignore
      when /\A\n(\t+)/
        if indent_type.nil?
          indent_type = $1.chr
        end
        row += 1
        column = $1.length
        raise 'mixed indent detected!' if ($1.split('') + [indent_type]).uniq.length != 1
        raise 'indent on empty line' if $'.chr == "\n"
        @q.push [:NEWLINE, '', row, 0] unless @q.last.first == :INDENT
        new_level = $1
        raise 'uneven indent, always use 2 spaces!' if indent_type == ' ' && new_level.length % 2 == 1
        depth = new_level.length / (indent_type == ' ' ? 2 : 1)
        diff = depth - indent_level
        if new_level.length > indent_string.length
          diff.abs.times{@q.push [:INDENT, $1, row, column]}
          indent_level += diff.abs
        elsif new_level.length < indent_string.length
          diff.abs.times{@q.push [:DEDENT, $1, row, column]}
          indent_level -= diff.abs
        end
        indent_string = new_level
      when /\A(true|false)/
        @q.push [:BOOL, $1, row, column]
        column += $1.length
      when /\A(-?)0x([0-9a-fA-F_]+)/
        @q.push [:NUMBER, ($1 == '-' ? -1 : 1) * Integer($2.tr('_', ''), 16), row, column]
        column += $1.length + 2 + $2.length
      when /\A(-?)([0-9_]+\.[0-9_]+)/
        @q.push [:NUMBER, ($1 == '-' ? -1 : 1) * $2.tr('_', '').to_f, row, column]
        column += $1.length + $2.length
      when /\A(-?)([0-9_]+)/
        @q.push [:NUMBER, ($1 == '-' ? -1 : 1) * Integer($2.tr('_', ''), 10), row, column]
        column += $1.length + $2.length
      when /\A"((?:[^"]|\\")+)"/
        @q.push [:STRING, $1, row, column]
        column += 2 + $1.length
      when /\A /
        @q.push [:SPACE, ' ', row, column]
        column += 1
      when /\A([:-])/
        @q.push [$1, '', row, column]
        column += 1
      when /\A\n/
        row += 1
        column = 0
        @q.push [:NEWLINE, '', row, column]
      when /\A([a-z0-9_-]+)/
        @q.push [:DICT_KEY, $1, row, column]
        column += $1.length
      else
        raise "could not tokenize '#{str}'"
      end
      start_of_file = false
      str = $'
    end
    # puts indent_level if $debug
    indent_level.times{@q.push [:DEDENT, $1, row, column]}
    @q.push [:EOF, 'EOF', row, column]
    # puts "tokens: #{@q.inspect}" if $debug
    @q.push [false, '$end', row, column]
    begin
      do_parse
    rescue
      raise "error parsing #{@current.first} at #{@current[2]}:#{@current[3]}"
    end
  end

  def next_token
    @current = @q.shift
    @current[0..1]
  end
---- footer

if __FILE__ == $PROGRAM_NAME
  p YAMLite.new().parse(File.read(ARGV.first))
end
# $debug = false
