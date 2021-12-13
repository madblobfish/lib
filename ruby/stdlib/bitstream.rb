class BitStream
  attr :current_bitoffset
  LSB_BYTEMASKS = [
    0b0000_0000,
    0b0000_0001,
    0b0000_0011,
    0b0000_0111,
    0b0000_1111,
    0b0001_1111,
    0b0011_1111,
    0b0111_1111,
  ]
  MSB_BYTEMASKS = [
    0b0000_0000,
    0b1000_0000,
    0b1100_0000,
    0b1110_0000,
    0b1111_0000,
    0b1111_1000,
    0b1111_1100,
    0b1111_1110,
  ]
  def initialize(io, dir=:msb)
    @io = io
    @current_byte = nil
    @current_bitoffset = 0
    @direction = dir
    raise 'give me a proper byte flow direction' unless %i(msb lsb).include?(dir)
  end
  def _read(bytes)
    ret = @io.read(bytes)
    raise EOFError, 'EoF yo' if ret.nil?
    ret
  end
  def mask_lsb(byte, len)
    byte.chr.unpack1('b*')[...len]
  end
  def mask_msb(byte, len)
    (byte.chr.unpack1('B*')[...len])
  end
  def eof?
    @io.eof?
  end
  def read(bytes, bytes_are_bits=false)
    return '' if bytes == 0
    if @current_byte.nil?
      # puts "# doin ez stuff"
      unless bytes_are_bits
        _read(bytes)
      else
        # read only some bits, but we currently are at a byte border
        first = _read((bytes/8).to_i)
        if bytes % 8 == 0
          first
        else
          @current_byte = _read(1).bytes.first
          @current_bitoffset = 8 - (bytes%8)
          first + (@current_byte >> @current_bitoffset).chr
        end
      end
    else
      # the two expensive bit shifting cases x.x
      if bytes_are_bits && bytes % 8 != 0
        first = _read((bytes/8).to_i)
        read_n_bits = (bytes%8)
        next_bitoffset = @current_bitoffset - read_n_bits
        puts "# doin bit shifting"
        # pp bytes
        # pp read_n_bits
        # pp @current_bitoffset
        mid_bits = ''
        post_bits = ''
        if next_bitoffset < 0
          puts "speziell"
          # pp next_bitoffset
          # pp read_n_bits
          next_byte = _read(1).bytes.first
          pre_bits = mask_lsb(@current_byte, read_n_bits)
          mid_bits = first.unpack1('b*')
          post_bits = mask_msb(next_byte, next_bitoffset.abs)
          @current_bitoffset = 8 + next_bitoffset
          @current_byte = next_byte
        elsif first != ''
          puts 'haii'
          pre_bits = mask_lsb((pp @current_byte), @current_bitoffset)
          mid_bits = pp first[...-1].unpack1('b*') + mask_lsb(((pp first)[-1]), bytes - @current_bitoffset)
          
          @current_byte = first[-1]
          @current_bitoffset = 8- (bytes - @current_bitoffset)
        else
          ret = ((@current_byte >> (next_bitoffset)) & LSB_BYTEMASKS[read_n_bits]).chr
          @current_bitoffset = next_bitoffset
          pre_bits = ret.unpack1('b*')
          #pre_bits = ((@current_byte >> (@current_bitoffset-1)) & LSB_BYTEMASKS[@current_bitoffset]).chr.unpack1('b*')
        end
        if @current_bitoffset == 0
          puts "unsetting current_byte"
          @current_byte = nil
        end
        [(pp ( pre_bits + mid_bits + post_bits))].pack('b*')
      else
        # the case where you got some bits left and want to read full bytes
        # (need to find the correct bits from the last byte to keep and shift everything around, yay)
        if bytes_are_bits
          first = _read((bytes/8).to_i)
        else
          first = _read(bytes)
        end
        first
        raise "fehlerfall hier fehlen die @current_byte bits"
      end
    end
  end
end


#f = File.open('/dev/random')
require 'stringio'
puts 'test B'
s = StringIO.new([0b0000_0000,0b0111_0010,0b1000_0111].pack('c*'))
b = BitStream.new(s)
raise 'OH' unless b.read(3, true) == "\x00"
# puts "CASE 2"
raise 'OH' unless (pp b.read(9, true)) == "@\x00"
# raise 'OH' unless (pp b.read(15, true).unpack1('b*')) == "\x00"


puts 'test A'
s = StringIO.new([0b0000_0000,0b0111_0010,0b1000_0111].pack('c*'))
b = BitStream.new(s)
raise 'AHH' if b.eof?
raise 'OH' unless b.read(1) == "\x00"
raise 'OH' unless b.read(2, true) == "\x01"
raise 'OH' unless b.current_bitoffset == 6
raise 'OH' unless (pp b.read(3, true)) == "\x06"
raise 'OH' unless b.current_bitoffset == 3
raise 'OH' unless b.read(3, true) == "\x02"
raise 'OH' unless b.current_bitoffset == 0
raise 'AHH' if b.eof?
raise 'OH' unless b.read(2, true) == "\x02"
raise 'OH' unless b.current_bitoffset == 6
raise 'AHH' if b.read(7, true) rescue false
raise 'AHH' unless b.eof?

__END__
LSB:

0000 0xxx | 0000 0000 | 0000 0000
read(1B 6bit)
2220 0000 | aa32 2222

MSB:
xxx0 1111 | 2222 3333 | 4444 5555
read(1B 6bit)
0111 1222 | 2333 34AA
