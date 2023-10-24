def wave_read(io)
  raise 'expected RIFF header' unless io.read(4) == 'RIFF'
  file_size = io.read(4).unpack1('L<')
  raise 'expected WAVE header' unless io.read(4) == 'WAVE'
  raise 'expected fmt header' unless io.read(4) == 'fmt '
  raise 'expected format header length of 16 bytes' unless (io.read(4).unpack1('L<')) == 16
  format = {1=>:pcm, 3=>:float}[io.read(2).unpack1('S<')]
  channels = io.read(2).unpack1('S<')
  sample_rate = io.read(4).unpack1('L<')
  _byte_rate = io.read(4).unpack1('L<')
  _block_align = io.read(2).unpack1('S<')
  bits_per_sample = io.read(2).unpack1('S<')
  raise 'expected data section' unless io.read(4) == 'data'
  data_size = io.read(4).unpack1('L<')

  pa_format =
    if format == :pcm && bits_per_sample == 8
      :U8
    elsif format == :pcm && bits_per_sample == 16
      :S16LE
    elsif format == :float && bits_per_sample == 32
      :FLOAT32LE
    else
      nil
    end

  [io, {size: data_size, ch: channels, sr: sample_rate, bps: bits_per_sample, fmt: format, pa_format: pa_format}]
end

if __FILE__ == $PROGRAM_NAME
  if ARGV.empty? || ARGV.include?('--help')
    puts 'Hi there, this is just a function to read the metadata from wave files.'
    puts 'But it also can play them using pa.rb'
    puts ' there are some options:'
    puts '  --play play once'
    puts '  --loop play forever'
    puts '  --loop-(start|end|length)-(byte|sample|sec|beat) <value> define when and how to loop, implies loop and play'
    puts '  --bpm <bpm> required for the -beat variants from above'
    exit
  end
  args = {}
  while (arg = ARGV.shift)
    args[:loop] = true if arg.match?(/\A--loop(\z|-end|-length)/)
    need_bpm = true if arg.end_with?('-beat')
    next if arg == '--loop'
    (args[:play] = true; next) if arg == '--play'
    if arg.start_with?('--loop-') || arg == '--bpm'
      args[arg[2..].tr('-', '_').to_sym] = ARGV.shift.to_f
    else
      ARGV.unshift(arg)
      break
    end
  end
  ARGV.map do |path|
    Thread.new do
      wav, meta = wave_read(File.open(path))
      print "Metadata ", path, ":\n", meta.map{|e| e.join(': ')}.join("\n"), "\n\n"
      if args[:play] || args[:loop]
        Signal.trap(0, proc { exit! 130 })
        require_relative 'pa.rb'
        PulseSimple.play_buffer(wav.read, **meta.merge(args))
      end
    end
  end.each{|t| t.join}
end
