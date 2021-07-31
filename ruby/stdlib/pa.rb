# see: https://freedesktop.org/software/pulseaudio/doxygen/simple.html
require 'ffi'

module PulseSimple
  extend FFI::Library
  ffi_lib 'libpulse-simple'

  enum :stream_dir, [:NODIRECTION, :PLAYBACK, :RECORD, :UPLOAD]

  enum :sample_format, [
    :U8,
    :ALAW, :ULAW,
    :S16LE, :S16BE,
    :FLOAT32LE, :FLOAT32BE,
    :S32LE, :S32BE,
    :S24LE, :S24BE,
    :S24_32LE, :S24_32BE,
    :MAX,
    :INVALID, -1]

  class SampleSpec < FFI::Struct
    layout :sample_format, :sample_format,
           :sample_rate, :uint32,
           :channels, :uint8
  end

  attach_function :pa_simple_new, [
      :string, # server (NULL=default)
      :string,  # app name
      :stream_dir, # direction
      :string, # device (NULL=default)
      :string, # Description of stream
      SampleSpec.by_ref, # sample format
      :pointer, # channel map (NULL=default)
      :pointer, # buffering attributes (NULL=default)
      :pointer # (out) int error code
    ], :pointer


  attach_function :pa_simple_read, [
    :pointer, # pa_simple pointer
    :buffer_out, # data data
    :size_t, # size in bytes
    :pointer, # (out) int error code
  ], :int # 0 if it works

  attach_function :pa_simple_write, [
    :pointer, # pa_simple pointer
    :buffer_in, # data data
    :size_t, # size in bytes
    :pointer, # (out) int error code
  ], :int, blocking: true

  attach_function :pa_simple_get_latency, [:pointer, :pointer], :uint64
  attach_function :pa_simple_drain, [:pointer, :pointer], :int, blocking: true
  attach_function :pa_strerror, [:int], :string
  attach_function :pa_simple_free, [:pointer], :void


  def self.handle_err(err)
    PulseSimple.pa_strerror(err.read(:int))
  end

  def self.gen_padding(len, char=' ')
    raise "bad padding" unless len % char.length == 0
    char * (len /char.length)
  end


  def self.open_stream(**opts, &block)
    o = {sr:48000, ch:1, pa_app: $PROGRAM_NAME, pa_description: '', pa_format: :FLOAT32LE}.merge(opts)
    ss = PulseSimple::SampleSpec.new
    ss[:sample_format] = o[:pa_format]
    ss[:sample_rate] = o[:sr]
    ss[:channels] = o[:ch]

    err = FFI::MemoryPointer.new(:int, 1)

    begin
      stream = PulseSimple.pa_simple_new(nil, o[:pa_app], :PLAYBACK, nil, o[:pa_description], ss, nil, nil, err)
      raise "Error connecting to PulseAudio: #{handle_err(err)}" if stream.null?
      block[stream, o, err]
    ensure
      PulseSimple.pa_simple_free(stream)
    end
  end

  def self.play(**opts, &block)
    open_stream(**opts) do |stream, o, err|
      buff = FFI::MemoryPointer.new(:float, o[:sr])
      t = -1
      loop do
        b = block[t+=1, o]
        if b.nil?
          # puts "hi"
          break
        end
        buff.write_bytes(b)
        raise "Error writing to PulseAudio: #{handle_err(err)}" unless PulseSimple.pa_simple_write(stream, buff, o[:sr], err) == 0
      end
      raise "Error draining PulseAudio: #{handle_err(err)}" unless PulseSimple.pa_simple_drain(stream, err) == 0
    end
  end

  def self.play_sample(**opts, &block)
    play(**opts.merge({ch:1})) do |t, opts|
      first = true
      out = Array.new(opts[:sr]) do |n|
        ret = block[t + n.to_f/opts[:sr], opts]
        if first
          first = false
          return nil if ret.nil?
        end
        ret.to_f
      end.pack('e*')
    end
  end

  def self.loop_buffer(buffer, **opts)
    buff = FFI::MemoryPointer.new(:float, buffer.bytesize)
    buff.write_bytes(buffer)
    open_stream(**opts) do |stream, o, err|
      loop do
        raise "Error writing to PulseAudio: #{handle_err(err)}" unless PulseSimple.pa_simple_write(stream, buff, buffer.bytesize, err) == 0
      end
    end
  end

  def self.bytestream(io, **opts)
    chunksize = opts.fetch(:chunksize, opts.fetch(:sr)*2)
    buff = FFI::MemoryPointer.new(:float, chunksize)
    open_stream(**opts) do |stream, o, err|
      until io.eof?
        buff.clear
        chunk.write_bytes(io.read(chunksize))
        raise "Error writing to PulseAudio: #{handle_err(err)}" unless PulseSimple.pa_simple_write(stream, buff, buffer.bytesize, err) == 0
      end
    end
  end
end

# Examples below, see also wav.rb

# PulseSimple.play(pa_format: :FLOAT32LE) do |t, o|
#   # Array.new(sr){rand(2)}.pack('e*') # noice
#   Array.new(o[:sr]){|n|Math.sin(220*(t*o[:sr] + n))}.pack('e*') # not a 220Hz sin ;) (see below for better way to do that)
# end

if __FILE__ == $PROGRAM_NAME
  puts 'sorry if this demo blows your speakers, or ears, or both, you are warned. press enter to continue'
  readline

  x = 0
  bla = false
  PulseSimple.play_sample do |t, o|
    x -= 1
    if (t*10000000).to_i % 3300000  == 0
      x = 5000
      bla = ! bla
    end
    if x > 0
      if bla
        rand(10)
      else
        Math.sin(130.0*t*Math::PI*2)
      end
    else
      Math.sin(220.0*t*Math::PI*2)
    end *0.25
  end
end
