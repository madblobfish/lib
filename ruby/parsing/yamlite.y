class YAMLite
rule
  # root
  target: document | NEWLINE document { result = val[1] }
  document: list EOF | dict EOF | eof

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
    | newline { result = nil }
  value: simple_value
    | newline INDENT list DEDENT { result = val[2] }
    | newline INDENT dict DEDENT { result = val[2] }

  newline: NEWLINE | NEWLINE newline

end

---- header
# Experimental strict parser for a subset of yaml
#
# it does not pass a single file from https://github.com/yaml/yaml-test-suite
#
# generated using: racc yamlite.y -o yamlite.rb
# $debug = true
---- inner
  def emit_indent()

  end
  def parse(str)
    # raise "not utf8" if str.force_encoding("UTF-8").valid_encoding?
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
        # row += 1
        column += 3
        # ignore
      when /\A(\n? *)#([^\n]+)/
        row += 1 if $1.include?("\n")
        # if @q.last == :NEWLINE
        #   @q.pop
        # else
        #   @q.push [:COMMENT, $2, row, $1.length + 1]
        # end
        # ignore
      # what did this try to archive?
      # when (@q.last || []).first != :INDENT && /\A #[^\n]+/
      #   # inline comment, ignore
      # when (@q.last || []).first == :INDENT && /\A#[^\n]+/
      #   # comment, ignore
      when /\A\n([\t ]+)/
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
      when /\A"((?:[^"\\]|\\.)+)"/
        column += 2 + $1.length
        escapes = {
          '\\"' => '"',
          '\\\\' => '\\',
          '\\0' => "\0",
        }
        escapes.default_proc = proc{|a,b| raise "invalid escape #{b}" }
        @q.push [:STRING, $1.gsub(/\\./, escapes){|m| raise mescapes[m]} , row, column]
        /\A"((?:[^"\\]|\\.)+)"/ =~ str # secretly fixing $'
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
        # peek for indentation and clear if no indent
        if str.match?(/\A\n[^ \t\n\z]/) && indent_level > 0
          indent_level.times{@q.push [:DEDENT, 'faked', row, column]}
          indent_level = 0
          indent_string = ''
        end
      when /\A([a-zA-Z0-9_.-]+)/
        @q.push [:DICT_KEY, $1, row, column]
        column += $1.length
      when /\A\r/
        raise "line-feed (\\r) not allowed"
      else
        raise "could not tokenize #{row}:#{column} '#{str.lines.take(5).join().rstrip}'"
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
  if ARGV.empty? || ARGV == ['--help']
    puts 'give me a file to parse, i output errors or json then'
  elsif ARGV == ['--selftest']
    ARGV = []
    require 'minitest'
    class TestMeme < Minitest::Test
      def test_asdf
        yl = YAMLite.new()
        Dir[__dir__ + '/yamlite_testfiles/valid/*.yaml'].each do |f|
          yl.parse(File.read(f))
        end
        Dir[__dir__ + '/yamlite_testfiles/bad/*.yaml'].each do |f|
          assert_raises{yl.parse(File.read(f))}
        end
      end
    end
    Minitest.autorun()
  else
    require 'json'
    puts JSON.pretty_generate(YAMLite.new().parse(File.read(ARGV.first)))
  end
end
# $debug = false
