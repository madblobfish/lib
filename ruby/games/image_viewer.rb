require_relative 'lib/gamelib'
require 'vips' rescue raise 'run "gem install ruby-vips", also install libjxl, libjxl-threads?, libvips, libopenslide'
require 'open3'

class ImageViewer < TerminalGame
  def initialize(agrgs)
    @require_kitty_graphics = true
    @draw_status_line = agrgs.delete('--no-status').nil? ? true : false
    if agrgs.delete('--rotate')
      @images_cycle = -1
      @fps = 1.0/5
      @rotate = true
    else
      @images_cycle = 0
      @fps = :manual
      @rotate = false
    end
    unless agrgs.size > 0
      raise 'feed me folders and/or images'
    end
    files = agrgs.flat_map{|f| File.directory?(f) ? Dir.children(f).map{|p|f+'/'+p} : File.readable?(f) ? f : nil}.compact
    @images = files.uniq.map do |f|
      begin
        [f.tr('//','/'), Vips::Image.new_from_file(f)]
      rescue Vips::Error
        cmd = ['ffmpeg', '-timelimit', '1', '-loglevel', 'quiet', '-ss', '1:20', '-i', f, '-vframes', '1', '-vcodec', 'png', '-an', '-f', 'image2pipe', '-']
        png, status = Open3.capture2(*cmd)
        if status == 0
          [f.tr('//','/'), Vips::Image.new_from_buffer(png, '')] rescue nil
        else
          nil
        end
      end
    end.compact
    unless @images.size > 0
      raise 'no (readable and supported) images found'
    end
    @images.reject!{|a,b| b.nil?}
    @skip_next_draw = false
    @roate_stopped = false
  end

  def initial_draw;sync_draw{draw(false)} unless @rotate;end
  def size_change_handler;sync_draw{draw(false, true)};end #redraw on size change

  def draw(cycle=true, redraw=false)
    unless redraw
      return if cycle && @roate_stopped
      if @skip_next_draw
        @skip_next_draw = false
        return
      end
      @images_cycle += 1 if @rotate and cycle
      @images_cycle %= @images.size if @rotate and cycle
    end
    current_filename, current_img = @images[@images_cycle]
    rowsize = @draw_status_line ? @size_row : 0
    scale_by = current_img.size.zip([@size_x, @size_y-rowsize]).map{|want,have| want > have ? have/want.to_f : 1}.min
    buffer = (scale_by == 1 ? current_img : current_img.resize(scale_by)).pngsave_buffer
    clear
    if @draw_status_line
      move_cursor(@rows,0)
      f = current_filename.inspect
      f += " (#{@images_cycle}/#{@images.size})" if @images.size > 1
      f += ' Paused' if @roate_stopped
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
    when " " #space
      @roate_stopped = ! @roate_stopped
    when "\e[C" #right
      @images_cycle += 1
      @images_cycle %= @images.size
    when "\e[D" #left
      @images_cycle -= 1
      @images_cycle = @images.size-1 if @images_cycle < 0
    else
      return
    end
    sync_draw do
      @skip_next_draw = false
      draw(false)
      @skip_next_draw = true
    end
  end
end

ImageViewer.new(ARGV).run() if __FILE__ == $PROGRAM_NAME
