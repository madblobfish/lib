def wave_read(io)
  raise 'expected RIFF header' unless io.read(4) == 'RIFF'
  file_size = io.read(4).unpack1('L<')
  raise 'expected WAVE header' unless io.read(4) == 'WAVE'
  raise 'expected fmt header' unless io.read(4) == 'fmt '
  raise 'expected format header length of 16 bytes' unless (io.read(4).unpack1('L<')) == 16
  format = {1=>:pcm, 3=>:float}[io.read(2).unpack1('S<')]
  channels = io.read(2).unpack1('S<')
  sample_rate = io.read(4).unpack1('L<')
  _sr2 = io.read(4).unpack1('L<')
  _bps2 = io.read(2).unpack1('S<')
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
    puts 'But it also can play them using pa.rb if you pass --play or --loop as the first argument'
    exit
  end
  loopy = false
  play = false
  if ARGV.first == '--play'
    ARGV.shift
    play = true
  end
  if ARGV.first == '--loop'
    ARGV.shift
    loopy = true
    play = true
  end
  ARGV.map do |path|
    Thread.new do
      wav, meta = wave_read(File.open(path))
      print "Metadata ", path, ":\n", meta.map{|e| e.join(': ')}.join("\n"), "\n\n"
      if play
        Signal.trap(0, proc { exit! 130 })
        require_relative 'pa.rb'
        if loopy
          PulseSimple.loop_buffer(wav.read(meta[:size]), **meta)
        else
          PulseSimple.bytestream(wav, **meta)
        end
      end
    end
  end.each{|t| t.join}
end