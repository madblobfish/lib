# It takes either a directory, a file or code as an argument,
# then it uses ruby_parser and sexp_processing and
# tries to find the method callchain.
#
# it uses sexp_processor, ruby_parser and my optsparser_generator.
#
# results can be output in csv, cypher and plaintext

require 'ruby_parser'
require 'sexp_processor'
require 'ostruct'
require 'pp'
require 'active_support/core_ext/object/blank'
gem 'optsparser_generator'#, '=2.6'
require 'optsparser_generator'

class MethodDependencyProcessor < MethodBasedSexpProcessor
  def initialize(options)
    super()
    @results = []
    @definitions = []
    @options = options.dup
    @variable_tracking = {}
  end

  def process_call(exp)
    @definitions << signature_to_def_name(signature)
    if method_name != '#none' && (exp[1].nil? && exp[1] != :lvar && exp[1] != :ivar)
      # puts 'type one'
      @results << [signature_to_def_name(signature), "#{klass_name}##{exp[2]}"]
      # puts @results.last
      # print "#{@def_stack.last}; #{exp[2]}\n"
    elsif method_name != '#none' && (exp[1][0] == :const) && !/^[[:upper:]_]+$/.match(exp[1][1])
      # puts 'type two'
      @results << [signature_to_def_name(signature), "#{exp[1][1]}##{exp[2]}"]
    elsif method_name != '#none' && (exp[1][0] == :lvar || exp[1][0] == :ivar)
      if @variable_tracking[exp[1][1]] && !@variable_tracking[exp[1][1]].blank?
        @results << [signature_to_def_name(signature), "#{@variable_tracking[exp[1][1]]}##{exp[2]}"]
        # pp @results.last
      end
    end
    exp.each do |sub_exp|
      process sub_exp if sub_exp.is_a?(Sexp)
    end
    exp
  end

  def process_lasgn(exp)
    varname = exp[1]
    assignment = exp[2]
    tracked_calls = []
    while !assignment.nil? && assignment[0] == :call
      tracked_calls << assignment[2]
      assignment = assignment[1]
    end
    if assignment
      if assignment[0] == :const && tracked_calls.pop == :new
        tracked_calls << assignment[1]
        tracked_calls.reverse!
        @variable_tracking[varname] = tracked_calls.join('::')
        # pp "#{tracked_calls.join('::')}.#{last_call}"
      elsif assignment[0] == :ivar
        @variable_tracking[varname] = assignment[1]
      else
        # pp assignment[0] if assignment
      end
    end
    exp.each do |sub_exp|
      process sub_exp if sub_exp.is_a?(Sexp)
    end
    exp
  end

  def signature_to_def_name(str)
    return str if str.include?('#') || str.include?('.')
    "#{str.split('::')[0..-2].join('::')}##{str.split('::').last}"
  end

  def print_results
    pp @results
  end

  def to_csv
    require 'csv'
    csv = CSV.generate do |csv|
      filter_results.each do |r|
        csv << r
      end
    end
    puts csv
  end

  def to_cypher
    name = 'a'
    query = ''
    @definitions.uniq!
    method_list = {}
    filter_results.flatten.uniq.each do |method|
      method_list[method] = name.succ!.dup
    end
    method_list.keys.each do |method|
      top_class = method.split('#').first.split('::').first
      query << "Create (#{method_list[method]}:Method:#{top_class} {name:'#{method}'})\n"
    end
    query << 'Create '
    filter_results.each do |connection|
      query << "(#{method_list[connection[0]]})-[:calls]->(#{method_list[connection[1]]}),\n"
    end
    query.chop!.chop!
    puts query
  end

  def filter_results
    return @results if @options.no_filter
    filter_end = %w(print puts require raise exit eval)
    filter_start = %w(CSV FileUtils File# JSON Time OpenStruct Rails Logger Dir OptionParser)
    out = []
    @results.each do |r|
      if !r[1].end_with?(*filter_end) && !r[1].start_with?(*filter_start)
        out << r
      end
    end
    out.map! do |k, v|
      v = "#{v[0..-4]}initialize" if @options.subsitute_new && v.end_with?('new')
      override = @definitions.select{ |define| define.include?(v) }.first
      [k, override.nil? ? v : override]
    end if @options.fix_method_names_with_known_ones
    out.uniq!
    out
  end
end

options = OpenStruct.new
options.output = 'csv'
options.output__help = 'defines the output format [csv,cypher,print]'
options.output__values = %w(csv cypher print)
options.no_filter = false
options.no_filter__help = 'filter the results'
options.subsitute_new = true
options.subsitute_new__help = '[filter option] changes new to point to initialize'
options.fix_method_names_with_known_ones = true
options.fix_method_names_with_known_ones__help = '[filter option] maps methods to found definitions, this helps against missing namespaces'

optsparser = OptParseGen(options)
optsparser.banner = 'usage: method_dependency_processor (Folder|File|RubyString)'

options = optsparser.parse!(ARGV)
if ARGV.one?
  code =
    if File.directory?(ARGV[0])
      Dir["#{ARGV[0]}/**/*.rb"].map { |dir| File.directory?(dir) ? '' : File.read(dir) }.join("\n")
    elsif File.readable?(ARGV[0])
      File.read(ARGV[0])
    else
      ARGV[0]
    end
else
  optsparser.parse! ['--help']
end

mdp = MethodDependencyProcessor.new(options)
mdp.process(RubyParser.new.parse(code))

case options.output
when 'csv'
  mdp.to_csv
when 'cypher'
  mdp.to_cypher
when 'print'
  mdp.print_results
end

# MATCH (n) DETACH DELETE n
# Match p=(a:Method)-[:calls]->(b:Method) Return p,a,a.name,b,b.name
