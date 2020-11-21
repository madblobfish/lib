# todo:
#   implement before command which also may get the inputs as cliargs or stdin. (optionally everything as well?)
#   implement after command which may gather some additional information
#   implement after optimize (ruby?) function which may be used to maximize or minimize something that the after command outputs
#   implement input processing (permutation, combination), maybe take ruby function?
#   parallelize?

require 'optsparser_generator'
require 'open3'

is_executeable_path = lambda do |f|
  return f unless f.delete_prefix!('@');
  raise "#{f.inspect} needs to be file and executable" unless File.file?(f) && File.executable?(f)
  return '@'+f
end
is_sh_or_file = lambda do |f|
  return f unless f.delete_prefix!('@');
  raise "File #{f.inspect} is not a file" unless File.file?(f)
  return '@'+f
end

defaults = OpenStruct.new
defaults.inputs = nil
defaults.inputs__class = String
defaults.inputs__proc = is_sh_or_file
defaults.test = nil
defaults.test__class = String
defaults.test__proc = is_executeable_path
defaults.test_instrumentation = "cliargs"
defaults.test_instrumentation__values = %w(cliargs, stdin, none)
defaults.test_timeout = nil
defaults.test_timeout__class = Numeric
defaults.test_timeout__proc = lambda{|n| raise "timeout needs to be above 0" if n <= 0 }
# defaults.before = nil
# defaults.before__class = String
# defaults.before__proc = is_executeable_path
# defaults.after = nil
# defaults.after__class = String
# defaults.after__proc = is_executeable_path
defaults.record_test_crashes = false
defaults.record_test_output = false
# defaults.record_after_output = false

opts = OptParseGen.parse!(defaults)
opts.test_instrumentation = opts.test_instrumentation.to_sym

raise "missing parameter: --inputs" unless opts.inputs
raise "missing parameter: --test" unless opts.test
record_mini = %i(record_test_crashes record_test_output)# record_after_output)
raise "should set one of #{record_mini.inspect}" if opts.to_h.values_at(*record_mini).count(true) == 0

# args are processed now :)

opts.test_is_file = opts.test.delete_prefix!('@')
opts.inputs_is_file = opts.inputs.delete_prefix!('@')

input =
  if opts.inputs_is_file
    File.open(opts.inputs)
  else
    stdin, stdout, opts.input_err = Open3.popen3('bash', '-c', opts.inputs)
    stdin.close
    stdout
  end

input.each_line do |line|
  line.chomp!
  stdin, stdout, stderr, wait_thread =
    if opts.test_is_file
      cmd = [opts.test]
      cmd += [line] if opts.test_instrumentation == :cliargs
      Open3.popen3(*cmd)
    else
      Open3.popen3(cmd.join(" "))
    end
  stdin.puts(line) if opts.test_instrumentation == :stdin
  stdin.close
  raise "thread did not" unless wait_thread.join(*[opts.test_timeout].compact)

  if opts.record_test_crashes
    status = wait_thread.value.exitstatus
    puts "input #{line.inspect} gave status code #{status}" if status != 0
  end
  if opts.record_test_output
    puts "output (stdout): #{stdout.read.inspect}"
    puts "output (stderr): #{stderr.read.inspect}"
  end
  # if opts.record_after_output
  # end
end
