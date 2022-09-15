require_relative 'lib/gamelib'
require_relative '../stdlib/color_palette.rb' rescue nil
require 'vips' rescue raise 'run "gem install ruby-vips", also install libjxl, libjxl-threads?, libvips, libopenslide'

class ImageViewer < TerminalGame
  def initialize(agrgs)
    @require_kitty_graphics = true
    @draw_status_line = agrgs.delete('--no-status')
    if agrgs.delete('--rotate')
      @fps = 1.0/5
      @rotate = true
    else
      @fps = :manual
      @rotate = false
    end
    unless agrgs.size > 0
      raise 'feed me folders and/or images'
    end
    files = agrgs.flat_map{|f| File.directory?(f) ? Dir.children(f).map{|p|f+'/'+p} : File.readable?(f) ? f : nil}
    @images = files.compact.uniq.map{|f| [f.tr('//','/'), Vips::Image.new_from_file(f)] rescue nil}.compact
    @images.reject!{|a,b| b.nil?}
    @images_cycle = 0
  end

  def initial_draw;;end #redraw on size change
  def size_change_handler;sync_draw{draw(false)};end #redraw on size change

  def draw(cycle=true)
    @images_cycle += 1 if @rotate and cycle
    @images_cycle %= @images.size if @rotate and cycle
    current_filename, current_img = @images[@images_cycle]
    rowsize = @draw_status_line ? @size_row : 0
    scale_by = current_img.size.zip([@size_x, @size_y-rowsize]).map{|want,have| want > have ? have/want.to_f : 1}.min
    buffer = (scale_by == 1 ? current_img : current_img.resize(scale_by)).pngsave_buffer
    if @draw_status_line
      move_cursor(@rows,0)
      clear
      f = current_filename.inspect
      f += " (#{@images_cycle}/#{@images.size})" if @images.size > 1
      print(' '*((@cols-f.length)/2))
      print(f)
    end
    move_cursor(0,0)
    imgid = kitty_graphics_img_load(buffer)
    kitty_graphics_img_pixel_place_center(imgid, *current_img.size.map{|e| (e*scale_by).to_i}, 0, -rowsize)
  end

  def input_handler(input)
    case input
    when "q"
      exit()
    when "\e[C" #right
      @images_cycle += 1
      @images_cycle %= @images.size
    when "\e[D" #left
      @images_cycle -= 1
      @images_cycle = @images.size-1 if @images_cycle < 0
    else
      return
    end
    sync_draw{draw(false)}
  end
end

ImageViewer.new(ARGV).run() if __FILE__ == $PROGRAM_NAME
