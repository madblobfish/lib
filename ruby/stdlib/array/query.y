class QueryParser
  prechigh
    nonassoc UNEG
    left '&&'
    left '||'
  preclow
rule
  target: exp

  val: VALUE | VALUE SPACE

  query:
    val '==' val {
      # puts "eql #{val}" if $debug
      result = lambda{|h| h[val[0]].to_s == val[2]}
    }
    | val '!=' val {
      # puts "not #{val}" if $debug
      result = lambda{|h| h[val[0]].to_s != val[2]}
    }
    | val OP_NUM val {
      # puts "num #{val}" if $debug
      result = lambda{|h| h[val[0]].to_f.send(val[1].to_sym, val[2].to_f) }
    }
    | 'has' val {
      # puts "has #{val}" if $debug
      result = lambda{|h| !(!h.has_key?(val[1]) || h[val[1]].nil? || h[val[1]] == '' ) }
    }
    | VALUE SPACE 'has' val {
      # puts "has #{val}" if $debug
      raise 'this syntax is deprecated use "field like regex"'
    }
    | VALUE SPACE 'in' val {
      # puts "in #{val}" if $debug
      vals = val[3].split(',').map(&:strip)
      result = lambda{|h|
        if not h.has_key?(val[0])
          raise "key '#{val[0]}' not found"
        elsif h[val[0]].class == Array
          (h[val[0]] & vals).any?
        else
          vals.include?(h[val[0]].to_s)
        end
      }
    }
    | VALUE SPACE 'all' val {
      # puts "all #{val}" if $debug
      vals = val[3].split(',').map(&:strip)
      result = lambda{|h|
        if not h.has_key?(val[0])
          raise "key '#{val[0]}' not found"
        elsif h[val[0]].class == Array
          (vals - h[val[0]]).empty?
        else
          false
        end
      }
    }
    | VALUE SPACE 'textsearch' val {
      # puts "textsearch #{val}" if $debug
      regexp = /#{val[3]}/i
      result = lambda{|h|
        cleanup = lambda{|v| v.gsub(/[.,:;!?'"-]/,' ').gsub(/\s\s+/, ' ')}
        if not h.has_key?(val[0])
          raise "key '#{val[0]}' not found"
        elsif h[val[0]].class == Array
          h[val[0]].any?{|v| cleanup[v].match?(regexp)}
        else
          cleanup[h[val[0]]].match?(regexp)
        end
      }
    }
    | VALUE SPACE 'like' val {
      # puts "like #{val}" if $debug
      regexp = /#{val[3]}/i
      result = lambda{|h|
        if not h.has_key?(val[0])
          raise "key '#{val[0]}' not found"
        elsif h[val[0]].class == Array
          h[val[0]].any?{|v| v.match?(regexp)}
        else
          h[val[0]].match?(regexp)
        end
      }
    }
    | VALUE SPACE SENSITIVE_LIKE val {
      # puts "sensitive like #{val}" if $debug
      regexp = /#{val[3]}/
      result = lambda{|h|
        if not h.has_key?(val[0])
          raise "key '#{val[0]}' not found"
        elsif h[val[0]].class == Array
          h[val[0]].any?{|v| v.match?(regexp)}
        else
          h[val[0]].match?(regexp)
        end
      }
    }

  exp:
    exp '||' exp {
      # puts 'or' if $debug
      result = lambda{|h| val[0][h] || val[2][h]} }
    | exp '&&' exp {
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
# generate using: racc query.y -o query.rb
# $debug = true
class Array
---- inner
  def parse(str)
    value_sub_subregex = '-\p{Hiragana}\p{Katakana}\p{Han}\p{Hangul}ー〜、a-zA-Z0-9_+*.⭐🩵💩'
    value_quoted_subregex = value_sub_subregex + "\|\(\) !?"
    value_subregex = "(\"[#{value_quoted_subregex}']+\"|'[#{value_quoted_subregex}\"]+'|[#{value_sub_subregex},]+)"
    @q = []
    until str.empty?
      case str
      when /\A\s+/ #ignore spaces
      when /\A(Like)\s+#{value_subregex}/
        @q.push [:SENSITIVE_LIKE, 'like']
        @q.push [:VALUE, $2.tr('"\'', '')]
      when /\A(all|in|has|like|textsearch)\s+#{value_subregex}/
        @q.push [$1, $1]
        @q.push [:VALUE, $2.tr('"\'', '')]
      when /\A#{value_subregex}(\s+)?/
        @q.push [:VALUE, $1.tr('"\'', '')]
        @q.push [:SPACE, ''] if $2
      when /\A[<>]=?/
        @q.push [:OP_NUM, $&]
      when /\A==|!=|\|\||&&|[!()\n]/o
        s = $&
        @q.push [s, s]
      else
        raise "could not tokenize '#{str}'"
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
---- footer
  def query(str)
    # puts "parsin" if $debug
    # puts str if $debug
    fun = QueryParser.new.parse(str)
    return self.select{|h|fun[h]}
  end
end
x = [
  {'a' => '1', 'b' => '1', 'c' => '3', 'd' => ['a', 'b', 'HIあああo']},
  {'a' => '1', 'b' => '2', 'c' => '3.4', 'd' => ['a', 'c']},
  {'a' => '1', 'b' => '2', 'c' => '4', 'd' => ['a', 'アあ']},
  {'a' => '1', 'b' => '2', 'c' => '4', 'd' => 'asd'},
  {'e' => '1', 'c' => '', 'd' => ''},
]
raise 'ah' unless x.query('!a == 1') == x.select{|h| h['a'] != '1'}
raise 'ahh' unless x.query('(!(!(a==1))&& b == 2)') == x.select{|h| h['a'] == '1' && h['b'] == '2'}
raise 'ahhh' unless x.query('c == 1 && b != 2') == x.select{|h| h['c'] == '1' && h['b'] != '2'}
raise 'ahhh2' unless x.query('c == 1 || b == 2') == x.select{|h| h['c'] == '1' || h['b'] == '2'}
raise 'ahhhh' unless x.query('c == 1 || b == 2 && c != 4') == x.select{|h| h['c'] == '1' || h['b'] == '2' && h['c'] != '4'}
raise 'ahhhhh' unless x.query('c == 1 || b == 2 && c != 4') == x.select{|h| h['c'] == '1' || (h['b'] == '2' && h['c'] != '4')}
raise 'ahhhhhh' unless x.query('(c == 1 || b == 2) && c != 4') == x.select{|h| (h['c'] == '1' || h['b'] == '2') && h['c'] != '4'}
raise 'ahhhhhhh' unless x.query('b != 2 || (c == 1 || b == 2) && c != 4') == x.select{|h| h['b'] != '2' || (h['c'] == '1' || h['b'] == '2') && h['c'] != '4'}
# raise 'ahhhhhhhh' unless x.query('d has d') == x.select{|h| [Array, String].include?(h['d'].class) && h['d'].include?('d')}
# raise 'ahhhhhhhhh' unless x.query('!(d has b)') == x.select{|h| ! h['d'].include?('b')}
# raise 'ahhhhhhhhhh' unless x.query('d has asd') == x.select{|h| h['d'].class == String && h['d'] == 'asd'}
raise 'ahhhhhhhhhhh' unless x.query('c > 3') == x.select{|h| h['c'].to_f > 3}
raise 'ahhhhhhhhhhhh' unless x.query('c > 3.3') == x.select{|h| h['c'].to_f > 3.3}
raise 'ahhhhhhhhhhhhh' unless x.query('(c > 2) || (c < 9)') == x.select{|h| h['c'].to_f > 2 || h['c'].to_f < 9}
raise 'ahhhhhhhhhhhhhh' unless x.query('c in 3,4') == x.select{|h| %w(3 4).include?(h['c'])}
raise 'ahhhhhhhhhhhhhhh' unless x.query('d in a,4') == x.select{|h| (%w(a 4) & h['d']).any? rescue false}
raise 'ahhhhhhhhhhhhhhhh' unless x.query('d all a,c') == x.select{|h| (%w(a c) - h['d']).empty? rescue false}
raise 'ahhhhhhhhhhhhhhhhh' unless x.query('d like あ+') == x.select{|h| h['d'].any?{|v| v.match?(/あ+/)} rescue false}
raise 'ahhhhhhhhhhhhhhhhha' unless x.query('d like hi') == x.select{|h| h['d'].any?{|v| v.match?(/^hi/i)} rescue false}
raise 'ahhhhhhhhhhhhhhhhhb' unless x.query('d like HI') == x.select{|h| h['d'].any?{|v| v.match?(/^HI/i)} rescue false}
raise 'ahhhhhhhhhhhhhhhhhc' unless x.query('d Like HI') == x.select{|h| h['d'].any?{|v| v.match?(/^HI/)} rescue false}
raise 'ahhhhhhhhhhhhhhhhhd' unless x.query('d Like hi') == x.select{|h| h['d'].any?{|v| v.match?(/^hi/)} rescue false}
raise 'ahhhhhhhhhhhhhhhhhh' unless x.query('d Like "hi"') == x.select{|h| h['d'].any?{|v| v.match?(/^hi/)} rescue false}
raise 'ahhhhhhhhhhhhhhhhhhh' unless x.query('has e') == x.select{|h| h.has_key?('e')}
raise 'ahhhhhhhhhhhhhhhhhhhh' unless x.query('has d') == x.select{|h| !(h['d'].nil? || h['d'] == '')}
[
  'c++',
  '(c) > 3',
  'c !> 3',
  '(c > 3',
  'c > 3)',
  'ahasb = b',
  'a == "b,',
  'a == \'b,',
  'a == b == c',
  'a has b has c',
  'a in b in c',
  'a all b all c',
  'a > b > c',
  'a like (a)',
  'a like ""',
  'a like \'\'',
  'a like \'a"',
  'a like "a\'',
  'a like [a]',
  'd has d',
  '!(d has b)',
  'd has asd',
].each_with_index do |str, i|
  begin
    x.query(str)
    raise ('ahn'+ 'o'*i) + ': ' + str
  rescue Racc::ParseError => e
    raise ('ahhn'+ 'o'*i) + ': ' + str unless e.to_s.strip.start_with?("parse error on value")
  rescue RuntimeError => e
    raise ('ahhn'+ 'o'*i) + ': ' + str unless e.to_s.start_with?('could not tokenize ') || e.to_s.start_with?('this syntax is deprecated use "field like regex"')
  end
end
# $debug = false
