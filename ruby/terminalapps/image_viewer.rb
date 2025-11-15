require_relative 'lib/gamelib'
require 'vips' rescue raise 'run "gem install ruby-vips", also install libjxl, libjxl-threads?, libvips, libopenslide'
Vips.cache_set_max_mem(1024*1024*1024)
require 'open3'

class ImageViewer < TerminalGame
  IMAGE_PLACEMENTS = [
    [0.5, 0.5], # middle middle / center
    [0  , 0  ], # top left
    [0.5, 0  ], # top middle
    [1  , 0  ], # top right
    [0  , 0.5], # middle left
    [1  , 0.5], # middle right
    [0  , 1  ], # bottom left
    [0.5, 1  ], # bottom middle
    [1  , 1  ], # bottom right
  ]
  def inspect #make errors short
    '#<ImageViewer>'
  end
  def initialize(agrgs)
    @require_kitty_graphics = true
    @draw_status_line = agrgs.delete('--no-status').nil? ? true : false
    @random = agrgs.delete('--random')
    @scale_up = :auto if agrgs.delete('--scale-up')
    @zoom = 1
    @zoom_pos = [0,0]
    @place = 0
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
    @images.shuffle! if @random
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
    current_filename, current_img, gif_params = @images[@images_cycle]
    rowsize = @draw_status_line ? @size_row : 0
    frames = []
    if gif_params
      frames = gif_params[0].times.map{|n| current_img.crop(0,gif_params[1]*n, current_img.size()[0], gif_params[1])}
      current_img = frames.first
    end
    scale_by = current_img.size.zip([@size_x, @size_y-rowsize]).map do |want,have|
      want > have ? have/want.to_f : (@scale_up == :auto ? have/want.to_f : 1)
    end.min
    if scale_by * @zoom != 1
      current_img = current_img.resize(scale_by*@zoom) #, kernel: :nearest)
      if @zoom != 1
        size = current_img.size()
        cutout_size = [@size_x, @size_y-rowsize].zip(size).map{|a,b|[[a,b].min,0].max}
        @zoom_pos = @zoom_pos.zip(size, cutout_size).map{|a,b,c|[a,b-c].min}
        current_img = current_img.crop(*@zoom_pos, *cutout_size)
      end
    end
    buffer = current_img.pngsave_buffer
    clear
    if @draw_status_line
      move_cursor(@rows,0)
      f = current_filename.inspect
      f += " (#{@images_cycle + 1}/#{@images.size})" if @images.size > 1
      f += ' %.0f%%' % (scale_by*@zoom*100) if @images.size > 1
      f += ' Paused' if @roate_stopped
      print(' '*((@cols-f.length)/2)) rescue nil
      print(f)
    end
    move_cursor(0,0)
    imgid = kitty_graphics_img_load(buffer)
    kitty_graphics_img_pixel_place(
      imgid,
      0,
      0,
      place: IMAGE_PLACEMENTS[@place],
      iw: current_img.size[0].to_i,
      ih: current_img.size[1].to_i,
      h: @size_y - rowsize,
    )
    # frames.each do |frame|
    #   if scale_by * @zoom != 1
    #     frame = frame.resize(scale_by*@zoom)
    #     if @zoom != 1
    #       size = frame.size()
    #       cutout_size = [@size_x, @size_y-rowsize].zip(size).map{|a,b|[[a,b].min,0].max}
    #       @zoom_pos = @zoom_pos.zip(size, cutout_size).map{|a,b,c|[a,b-c].min}
    #       frame = frame.crop(*@zoom_pos, *cutout_size)
    #     end
    #   end
    #   id = kitty_graphics_img_load(frame.pngsave_buffer)
    #   kitty_graphics_img_pixel_place_center(id, *frame.size.map{|e| (e).to_i}, 0, -rowsize)
    # end
  end

  def input_handler(input)
    case input
    when "-"
      @zoom /= 1.5
    when "+"
      @zoom *= 1.5
    when "q", "\e" # escape
      exit()
    when " " # space
      @roate_stopped = ! @roate_stopped
    when "\e[C" # right
      @images_cycle += 1
      @images_cycle %= @images.size
      @zoom_pos = [0,0]
      @zoom = 1
    when "\e[D" # left
      @images_cycle -= 1
      @images_cycle = @images.size-1 if @images_cycle < 0
      @zoom_pos = [0,0]
      @zoom = 1
    when "\e[1;5A" # ctrl up
      @zoom_pos[1] -= @size_y/5
      @zoom_pos[1] = 0 if @zoom_pos[1] < 0
    when "\e[1;5B" # ctrl down
      @zoom_pos[1] += @size_y/5
    when "\e[1;5C" # ctrl right
      @zoom_pos[0] += @size_x/5
    when "\e[1;5D" # ctrl left
      @zoom_pos[0] -= @size_x/5
      @zoom_pos[0] = 0 if @zoom_pos[0] < 0
    when "p"
      @place += 1
      @place %= IMAGE_PLACEMENTS.length
    else
      # raise input.inspect # for implementing new commands
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
