require_relative 'lib/gamelib'

def BMP_to_arr(buffer)
  a = buffer.b
  raise 'BMP header broken' unless a[0...2] == 'BM'
  raise 'unsupported BMP color depth' unless a[28...30].unpack("S") == [24]
  raise 'unsupported BMP encoding' unless a[30...34].unpack('L<') == [0]
  raise 'unsupported BMP palette' unless a[46...50].unpack('L<') == [0]
  file_size = a[2...6].unpack('L<')[0]
  size = a[18...26].unpack('L<*')
  offset = a.b[10..14].unpack('L<')[0]
  a[offset..file_size].each_byte.each_slice((8*3*size[0]+31)/32*4).map{|s|s.each_slice(3).to_a.reject{|s|s.length != 3}}.take(size[1]).reverse
end
def arr_to_BMP(arr)
  # BMP Header
  buff = 'BM'.b
  buff += "\x00\x00\x00\x00" # file size
  buff += "\x00\x00\x00\x00" # unused
  buff += "\x36\x00\x00\x00" # offset
  # DIB Header
  buff += "\x28\x00\x00\x00" # size
  buff += [arr.first.length].pack('L<') # width
  buff += [arr.length].pack('L<') # height
  buff += "\x01\x00" # color planes
  buff += "\x18\x00" # bits per pixel
  buff += "\x00\x00\x00\x00" # uncompressed
  buff += "\x00\x00\x00\x00" # bitmapdata_size
  buff += "\x00\x00\x00\x00\x00\x00\x00\x00" # printresolution
  buff += "\x00\x00\x00\x00" # color palette
  buff += "\x00\x00\x00\x00" # important colors
  arr.each do |r|
    r.each{|rgb| rbg.each{|e|buff << e} }
    buff += "\0" * ((r.length*3)%4) #pad
  end
  buff
end

class MSPaint < TerminalGame
  def initialize(img_path='/home/asd/Bilder/screenshot-2020-07-19-11:42:56.png')
    require 'open3'
    buffer, status = Open3.capture2('convert', img_path, 'bmp:-')
    raise 'could not import image' unless status == 0
    @img = BMP_to_arr(buffer)
    @mouse_support = true
    @mouse_pressed = false
  end
  def draw
    move_cursor
    @img.each{|r| r.each{|rgb| color(rgb); print '██' }; print "\r\n"}
  end
  def mouse_handler(x, y, button_id, state)
    if button_id == 0
      @mouse_pressed = state == :up
    end
    @img[y][x/2] = [255,255,255] if @mouse_pressed
  end
  def input_handler(data)
    exit(0) if data == 'q'
  end
end

MSPaint.new(*ARGV).run if __FILE__ == $PROGRAM_NAME
