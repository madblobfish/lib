require 'parslet'
# $debug = true
class Mini < Parslet::Parser
  rule(:space)  { match[" "].repeat(1) }
  rule(:space?) { space.maybe }

  rule(:brack_left) { str("(") >> space? }
  rule(:brack_right) { str(")") >> space? }
  rule(:neg) { str("!") >> space? }

  rule(:op_eql) { str('==') >> space? }
  rule(:op_not) { str('!=') >> space? }
  rule(:op_and) { str("&&") >> space? }
  rule(:op_in) { str("in") }
  rule(:op_has) { str("has") }
  rule(:op_or)  { str("||") >> space? }
  rule(:op_num) { match('<') >> match('=').maybe >> space? | match('>') >> match('=').maybe >> space? }

  rule(:value) { match["a-zA-Z0-9_."].repeat(1) }

  rule(:exp_eql) { value.as(:left) >> space? >> op_eql.as(:eql) >> value.as(:right) >> space? }
  rule(:exp_not) { value.as(:left) >> space? >> op_not.as(:not) >> value.as(:right) >> space? }
  rule(:exp_num) { value.as(:left) >> space? >> op_num.as(:numeric) >> value.as(:right) >> space? }
  rule(:exp_in) { value.as(:left) >> space >> op_in.as(:in) >> space >> value.as(:right) >> space? }
  rule(:exp_has) { value.as(:left) >> space >> op_has.as(:has) >> space >> value.as(:right) >> space? }
  rule(:exp) { exp_eql | exp_not | exp_num | exp_in | exp_has }

  rule(:primary) { neg.as(:unineg) >> brack_left >> or_operation.as(:exp) >> brack_right | brack_left >> or_operation >> brack_right | exp }

  rule(:and_operation) { (primary.as(:left) >> op_and.as(:and) >> and_operation.as(:right)) | primary}
  rule(:or_operation)  { (and_operation.as(:left) >> op_or.as(:or) >> or_operation.as(:right)) | and_operation}

  # start at the lowest precedence rule.
  root(:or_operation)
end
class Array
  #   key==value: equals
  #   a<=b, a>=b: converts to float then compares, also without equals
  #   key!=value: does not equal
  #   value in array_key: array_key includes value
  #   !(exp): logical not
  #   (exp): brackets
  #   exp&&exp: logical and
  #   exp||exp: logical or
  def query(query_str)
    fun = transform(Mini.new.parse(query_str))
    return self.select{|v| fun[v]}
  rescue Parslet::ParseFailed => failure
    # puts failure.parse_failure_cause.ascii_tree if $debug
    raise
  end

  def transform(tree)
    # tree[:op] = tree[:op].to_s
    case tree
    in brack:
      # puts "and" if $debug
      # puts left, right if $debug
      p brack
      exp = transform(brack)
      lambda{|h| exp[h]}
    in and:, left:, right:
      # puts "and" if $debug
      # puts left, right if $debug
      l,r = transform(left), transform(right)
      lambda{|h| l[h] && r[h]}
    in or:, left:, right:
      # puts "or" if $debug
      # puts left, right if $debug
      l,r = transform(left), transform(right)
      lambda{|h| l[h] || r[h]}
    in unineg:, exp:
      # puts "negative" if $debug
      neg = transform(exp)
      lambda{|h| ! neg[h]}
    in eql:, left:, right:
      # puts "equal" if $debug
      # p left, right if $debug
      lambda{|h| h[left.to_s].to_s == right.to_s }
    in not:, left:, right:
      # puts "not equal" if $debug
      lambda{|h| h[left.to_s].to_s != right.to_s }
    in has:, left:, right:
      # puts "has" if $debug
      lambda{|h| (h[left.to_s].map(&:to_s) rescue h[left.to_s]).include?(right.to_s) rescue false}
    in in:, left:, right:
      # puts "in" if $debug
      vals = right.to_s.split(',').map(&:strip)
      lambda{|h| vals.include?(h[left.to_s].to_s) }
    in numeric:, left:, right:
      # puts "numeric" if $debug
      lambda{|h| h[left.to_s].to_f.send(numeric.to_s.strip.to_sym, right.to_s.to_f) }
    else
      raise "could not parse/transform: #{tree}"
    end
  end
end

# $debug = false
x = [
  {'a' => '1', 'b' => '1', 'c' => '3', 'd' => ['a', 'b']},
  {'a' => '1', 'b' => '2', 'c' => '3.4', 'd' => ['a', 'c']},
  {'a' => '1', 'b' => '2', 'c' => '4', 'd' => ['a']},
  {'a' => '1', 'b' => '2', 'c' => '4', 'd' => 'asd'},
]
raise 'ah' unless x.query('a == 1') == x.select{|h| h['a'] == '1'}
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
# $debug = true
x.query("(aaaaa == b && a > aaaaaaaa) || !(aaaaaaaaaaaaaaaaaaaaaaaaaaaaa == b)")
# x.query("(state == seen &&year > 2023) || !(title has Gintama && genres has Action)")
[
  '(c) > 3',
  'c !> 3',
  '(c > 3',
  'c > 3)',
  'ahasb = b',
  'a == b,',
  'a == b == c',
  'a has b has c',
  'a > b > c',
  '',
].each_with_index do |str, i|
  begin
    x.query(str)
    raise ('ahn'+ 'o'*i)
  rescue Parslet::ParseFailed => e
    raise ('ahhn'+ 'o'*i) unless e.to_s.start_with?('Expected one of [')
  end
end
# $debug = true
