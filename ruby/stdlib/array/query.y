class QueryParser
  prechigh
    nonassoc UNEG
    left OP_AND
    left OP_OR
  preclow
rule
  target: exp

  val: VALUE | VALUE_AND_SPACE
  query:
    val OP_EQL val {
      # puts "eql #{val}" if $debug
      result = lambda{|h| h[val[0]].to_s == val[2]} }
    | val OP_NOT val {
      # puts "not #{val}" if $debug
      result = lambda{|h| h[val[0]].to_s != val[2]} }
    | val OP_NUM val {
      # puts "num #{val}" if $debug
      result = lambda{|h| h[val[0]].to_f.send(val[1].to_sym, val[2].to_f) } }
    | VALUE_AND_SPACE OP_HAS val {
      # puts "has #{val}" if $debug
      result = lambda{|h| (h[val[0]].map(&:to_s) rescue h[val[0]].to_s).include?(val[2]) rescue false}
    }
    | VALUE_AND_SPACE OP_IN val {
      # puts "in #{val}" if $debug
      vals = val[2].split(',').map(&:strip)
      result = lambda{|h|
        if h[val[0]].class == Array
          (h[val[0]] & vals).any?
        else
          vals.include?(h[val[0]].to_s)
        end
      }
    }
    | VALUE_AND_SPACE OP_ALL val {
      # puts "all #{val}" if $debug
      vals = val[2].split(',').map(&:strip)
      result = lambda{|h|
        if h[val[0]].class == Array
          (vals - h[val[0]]).empty?
        else
          false
        end
      }
    }
  exp:
    exp OP_OR exp {
      # puts 'or' if $debug
      result = lambda{|h| val[0][h] || val[2][h]} }
    | exp OP_AND exp {
      # puts 'and' if $debug
      result = lambda{|h| val[0][h] && val[2][h]} }
    | '!' exp =UNEG {
      # puts 'not' if $debug
      result = lambda{|h| ! val[1][h] } }
    | '(' exp ')' {
      # puts 'brack' if $debug
      result = val[1] }
    | query
end

---- header
# $debug = false
class Array
---- footer
  def query(str)
    # puts "parsin" if $debug
    # puts str if $debug
    fun = QueryParser.new.parse(str)
    return self.select{|h|fun[h]}
  end
end
x = [
  {'a' => '1', 'b' => '1', 'c' => '3', 'd' => ['a', 'b']},
  {'a' => '1', 'b' => '2', 'c' => '3.4', 'd' => ['a', 'c']},
  {'a' => '1', 'b' => '2', 'c' => '4', 'd' => ['a']},
  {'a' => '1', 'b' => '2', 'c' => '4', 'd' => 'asd'},
]
raise 'ah' unless x.query('!a == 1') == x.select{|h| h['a'] != '1'}
raise 'ahh' unless x.query('(!(!(a==1))&& b == 2)') == x.select{|h| h['a'] == '1' && h['b'] == '2'}
raise 'ahhh' unless x.query('c == 1 && b != 2') == x.select{|h| h['c'] == '1' && h['b'] != '2'}
raise 'ahhh2' unless x.query('c == 1 || b == 2') == x.select{|h| h['c'] == '1' || h['b'] == '2'}
raise 'ahhhh' unless x.query('c == 1 || b == 2 && c != 4') == x.select{|h| h['c'] == '1' || h['b'] == '2' && h['c'] != '4'}
raise 'ahhhhh' unless x.query('c == 1 || b == 2 && c != 4') == x.select{|h| h['c'] == '1' || (h['b'] == '2' && h['c'] != '4')}
raise 'ahhhhhh' unless x.query('(c == 1 || b == 2) && c != 4') == x.select{|h| (h['c'] == '1' || h['b'] == '2') && h['c'] != '4'}
raise 'ahhhhhhh' unless x.query('b != 2 || (c == 1 || b == 2) && c != 4') == x.select{|h| h['b'] != '2' || (h['c'] == '1' || h['b'] == '2') && h['c'] != '4'}
raise 'ahhhhhhhh' unless x.query('d has d') == x.select{|h| [Array, String].include?(h['d'].class) && h['d'].include?('d')}
raise 'ahhhhhhhhh' unless x.query('!(d has b)') == x.select{|h| ! h['d'].include?('b')}
raise 'ahhhhhhhhhh' unless x.query('d has asd') == x.select{|h| h['d'].class == String && h['d'] == 'asd'}
raise 'ahhhhhhhhhhh' unless x.query('c > 3') == x.select{|h| h['c'].to_f > 3}
raise 'ahhhhhhhhhhhh' unless x.query('c > 3.3') == x.select{|h| h['c'].to_f > 3.3}
raise 'ahhhhhhhhhhhhh' unless x.query('(c > 2) || (c < 9)') == x.select{|h| h['c'].to_f > 2 || h['c'].to_f < 9}
raise 'ahhhhhhhhhhhhhh' unless x.query('c in 3,4') == x.select{|h| %w(3 4).include?(h['c'])}
raise 'ahhhhhhhhhhhhhhh' unless x.query('d in a,4') == x.select{|h| (%w(a 4) & h['d']).any? rescue false}
raise 'ahhhhhhhhhhhhhhhh' unless x.query('d all a,c') == x.select{|h| (%w(a c) - h['d']).empty? rescue false}
[
  '(c) > 3',
  'c !> 3',
  '(c > 3',
  'c > 3)',
  'ahasb = b',
  'a == b,',
  'a == b == c',
  'a has b has c',
  'a in b in c',
  'a all b all c',
  'a > b > c',
  '',
].each_with_index do |str, i|
  begin
    x.query(str)
    raise ('ahn'+ 'o'*i) + ': ' + str
  rescue Racc::ParseError => e
    raise ('ahhn'+ 'o'*i) + ': ' + str unless e.to_s.start_with?("\nparse error on value")
  rescue RuntimeError => e
    raise ('ahhn'+ 'o'*i) + ': ' + str unless e.to_s.start_with?("could not tokenize")
  end
end
# $debug = true
---- inner

  def parse(str)
    @q = []
    until str.empty?
      case str
      when /\A\s+/ #ignore spaces
      when /\Aall\s+([a-zA-Z0-9_.,-]+)/
        @q.push [:OP_ALL, 'all']
        @q.push [:VALUE, $1]
      when /\Ain\s+([a-zA-Z0-9_.,-]+)/
        @q.push [:OP_IN, 'in']
        @q.push [:VALUE, $1]
      when /\Ahas\s+([a-zA-Z0-9_.,-]+)/
        @q.push [:OP_HAS, 'has']
        @q.push [:VALUE, $1]
      when /\A[a-zA-Z0-9_.-]+\s+/
        @q.push [:VALUE_AND_SPACE, $&.strip]
      when /\A[a-zA-Z0-9_.-]+/
        @q.push [:VALUE, $&]
      when /\A==/
        @q.push [:OP_EQL, '==']
      when /\A!=/
        @q.push [:OP_NOT, '!=']
      when /\A[<>]=?/
        @q.push [:OP_NUM, $&]
      when /\A&&/
        @q.push [:OP_AND, '&&']
      when /\A\|\|/
        @q.push [:OP_OR, '||']
      when /\A[!()\n]|\|\||&&/o
        s = $&
        @q.push [s, s]
      else
        raise "could not tokenize #{str}"
      end
      str = $'
    end
    # puts "tokens: #{@q.inspect}" if $debug
    @q.push [false, '$end']
    do_parse
  end

  def next_token
    @q.shift
  end
