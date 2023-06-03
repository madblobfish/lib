# $debug = true
class Array
  def query_lambda(query_str)
    # p query_str if $debug
    case query_str
    when /^\s*(!\s*)?\(\s*(.+)\s*\)\s*$/
      # puts 'bracket' if $debug
      l = query_lambda($2)
      $1 ? lambda{|h| not l[h]} : l
    when /^([^|()]+)\|\|(.+)$/, /^(.+)\|\|([^|()]+)$/
      # puts 'or' if $debug
      # p $1, $2 if $debug
      parts = [query_lambda($1), query_lambda($2)]
      lambda{|h| parts.any?{|l| l[h]}}
    when /^([^&|()]+)\&\&(.+)$/, /^(.+)\&\&([^&|()]+)$/
      # puts 'and' if $debug
      parts = query_str.split('&&').map{|s| query_lambda(s)}
      lambda{|h| parts.all?{|l| l[h]}}
    when /^\s*([a-z0-9_]+)\s+has\s+([a-z0-9_]+)\s*$/i
      # puts 'array has' if $debug
      lambda{|h| (h[$1].map(&:to_s) rescue h[$1]).include?($2) rescue false}
    when /^\s*([a-z0-9_]+)\s*(<=?|>=?)\s*([a-z0-9_]+)\s*$/i
      # puts 'comp' if $debug
      lambda{|h| h[$1].to_f.send($2.to_sym, $3.to_f)}
    when /^\s*([a-z0-9_]+)\s*\!\=\s*([a-z0-9_]+)\s*$/i
      # puts 'not equals' if $debug
      lambda{|h| h[$1].to_s != $2}
    when /^\s*([a-z0-9_]+)\s*\=\=\s*([a-z0-9_]+)\s*$/i
      # puts 'equals' if $debug
      lambda{|h| h[$1].to_s == $2}
    else
      raise "could not parse: #{query_str.inspect}"
    end
  end
  # works on array which contains Hashs with string keys and string values for now
  # query syntax and priority (highest first):
  #   key==value: equals
  #   a<=b, a>=b: converts to float then compares, also without equals
  #   key!=value: does not equal
  #   value in array_key: array_key includes value
  #   !(exp): logical not
  #   (exp): brackets
  #   exp&&exp: logical and
  #   exp||exp: logical or
  def query(query_str)
    fun = query_lambda(query_str)
    return self.select{|v| fun[v]}
  end
end

# $debug = false
x = [
  {'a' => '1', 'b' => '1', 'c' => '3', 'd' => ['a', 'b']},
  {'a' => '1', 'b' => '2', 'c' => '3', 'd' => ['a', 'c']},
  {'a' => '1', 'b' => '2', 'c' => '4', 'd' => ['a']},
]
raise 'ah' unless x.query('a == 1') == x.select{|h| h['a'] == '1'}
raise 'ahh' unless x.query('(!(!(a == 1)) && b == 2)') == x.select{|h| h['a'] == '1' && h['b'] == '2'}
raise 'ahhh' unless x.query('c == 1 && b != 2') == x.select{|h| h['c'] == '1' && h['b'] != '2'}
raise 'ahhh2' unless x.query('c == 1 || b == 2') == x.select{|h| h['c'] == '1' || h['b'] == '2'}
raise 'ahhhh' unless x.query('c == 1 || b == 2 && c != 4') == x.select{|h| h['c'] == '1' || h['b'] == '2' && h['c'] != '4'}
raise 'ahhhhh' unless x.query('c == 1 || b == 2 && c != 4') == x.select{|h| h['c'] == '1' || (h['b'] == '2' && h['c'] != '4')}
raise 'ahhhhhh' unless x.query('(c == 1 || b == 2) && c != 4') == x.select{|h| (h['c'] == '1' || h['b'] == '2') && h['c'] != '4'}
raise 'ahhhhhhh' unless x.query('b != 2 || (c == 1 || b == 2) && c != 4') == x.select{|h| h['b'] != '2' || (h['c'] == '1' || h['b'] == '2') && h['c'] != '4'}
raise 'ahhhhhhhh' unless x.query('d has d') == x.select{|h| h['d'].include?('d')}
raise 'ahhhhhhhhh' unless x.query('!(d has b)') == x.select{|h| ! h['d'].include?('b')}
raise 'ahhhhhhhhhh' unless x.query('c > 3') == x.select{|h| h['c'].to_f > 3}
[
  '(c) > 3',
  'c !> 3',
  '(c > 3',
  'c > 3)',
  'ahasb = b',
  'a == b,',
  '',
].each_with_index do |str, i|
  begin
    x.query(str)
    raise ('ahn'+ 'o'*i)
  rescue => e
    raise ('ahhn'+ 'o'*i) unless e.to_s.start_with?('could not parse: "')
  end
end
