#!/usr/bin/env ruby
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

  private
  def self.handle_err(err)
    PulseSimple.pa_strerror(err.read(:int))
  end

  def self.gen_padding(len, char=' ')
    raise "bad padding" unless len % char.length == 0
    char * (len /char.length)
  end

  def self.beat_to_sec(beat, **opts)
    beat / (opts[:bpm]/60.0)
  end
  def self.sec_to_sample(sec, **opts)
    (sec * opts[:sr]).to_i
  end
  def self.sample_to_byte(sample, **opts)
    sample * opts[:ch] * opts[:bps]/8
  end
  def self.sec_to_byte(sec, **opts)
    sample_to_byte(sec_to_sample(sec, **opts), **opts)
  end

  def self.get_bytes(prefix, default=nil, **opts)
    if opts.has_key?(key = (prefix+'_byte').to_sym)
      opts[key]
    elsif opts.has_key?(key = (prefix+'_samples').to_sym)
      sample_to_byte(opts[key], **opts)
    elsif opts.has_key?(key = (prefix+'_sec').to_sym)
      sec_to_byte(opts[key], **opts)
    elsif opts.has_key?(key = (prefix+'_beat').to_sym)
      sec_to_byte(beat_to_sec(opts[key], **opts), **opts)
    else
      raise "did not find definition for #{prefix}_(byte|samples|sec|bpm) in opts" if default.nil?
      default
    end
  end


  # you're probably looking for one of the below ones
  def self.open_stream(**opts, &block)
    o = {sr:48000, ch:1, pa_app: File.basename($PROGRAM_NAME), pa_description: '', pa_format: :FLOAT32LE}.merge(opts)
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

  public
  def self.stream_chunks(**opts, &block)
    open_stream(**opts) do |stream, o, err|
      buff = FFI::MemoryPointer.new(:float, o[:sr])
      t = -1
      loop do
        b = block[t+=1, o]
        break if b.nil?
        buff.write_bytes(b)
        raise "Error writing to PulseAudio: #{handle_err(err)}" unless PulseSimple.pa_simple_write(stream, buff, o[:sr], err) == 0
      end
      # raise "Error draining PulseAudio: #{handle_err(err)}" unless PulseSimple.pa_simple_drain(stream, err) == 0
    end
  end
  def self.stream_samples(**opts, &block)
    o = {pa_format: :FLOAT32LE}.merge(opts)
    stream_chunks(**o) do |t, opts|
      first = true
      out = Array.new(opts[:sr]) do |n|
        ret = block[t*opts[:sr] + n, opts]
        if first
          first = false
          return nil if ret.nil?
        end
        ret.to_f
      end
      case opts[:pa_format]
      when :U8
        out.pack('C*')
      when :FLOAT32LE
        out.pack('e*')
      else
        raise "unsupported"
      end
    end
  end

  # some doc in wav.rb --help
  def self.play_buffer(buffer, **opts)
    open_stream(**opts) do |stream, o, err|
      if o[:loop] && (o.has_key?(:loop_start_beat) || o.has_key?(:loop_start_sec) || o.has_key?(:loop_start_sample))
        o[:loop_start_byte] = get_bytes('loop_start', **opts)
        prebuff = FFI::MemoryPointer.new(:float, o[:loop_start_byte])
        prebuff.write_bytes(buffer.byteslice(0, o[:loop_start_byte]))
        raise "Error writing to PulseAudio: #{handle_err(err)}" unless PulseSimple.pa_simple_write(stream, prebuff, o[:loop_start_byte], err) == 0
      end
      o[:loop_end_byte] = get_bytes('loop_end', false, **opts)
      o[:loop_length_byte] = get_bytes('loop_length', false, **opts)
      buffer_len =
        if o[:loop_length_byte] && o[:loop]
          o[:loop_length_byte]
        elsif o[:loop_end_byte] && o[:loop]
          o[:loop_end_byte] - o.fetch(:loop_start_byte, 0)
        else
          o[:size] || buffer.bytesize # buffersize may be padded! the given size is what we trust
        end
      raise 'loop end needs to be before beginning || buffer too small' if buffer_len <= 0
      buff = FFI::MemoryPointer.new(:float, buffer_len)
      buff.write_bytes(buffer.byteslice(o[:loop] ? o.fetch(:loop_start_byte, 0) : 0, buffer_len))
      begin
        raise "Error writing to PulseAudio: #{handle_err(err)}" unless PulseSimple.pa_simple_write(stream, buff, buffer_len, err) == 0
      end while o[:loop]
    end
  end
end

# Examples below, see also wav.rb

# PulseSimple.stream_chunks do |t, o|
#   # Array.new(sr){rand()}.pack('e*') # noice
#   Array.new(o[:sr]){|n|Math.sin(220*(t*o[:sr] + n))}.pack('e*') # not a 220Hz sin ;) (see below for better way to do that)
# end

# PulseSimple.stream_samples do |t|
#   # rand() # noice
#   Math.sin(220*t*Math::PI*2) # 220Hz sin
# end

if __FILE__ == $PROGRAM_NAME
  if ARGV.empty? || ARGV.first == '--help'
    print __FILE__, ': [sample_rate] [format(u8|float32le)] <bytebeat code>', ''
    puts 'pass in ruby code as last argument to eval'
    puts 'you get the playbacktime in seconds as t and an options hash as o'
    puts 'return an integer or float, this then will be played back'
    puts ''
    puts 'Examples:'
    puts '  pa.rb "(42 & t >>10)*t"'
    puts '  pa.rb 48000 float32le "return nil if t>100000; Math.sin(220.0*t*2*Math::PI/48000)"'
    exit
  end
  x = eval("lambda{|t| #{ARGV.last} }")
  PulseSimple.stream_samples(
    pa_description: 'the thing you ran in the console',
    pa_format: {'u8'=> :U8, 'float32le'=> :FLOAT32LE}.fetch(ARGV[1]&.downcase, :U8),
    sr: (Integer(ARGV[0]) rescue 8000),
  ){|t,o| x[t+2700]}
end
