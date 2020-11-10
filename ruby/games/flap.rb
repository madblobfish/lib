require_relative 'lib/gamelib.rb'

class Bla < TerminalGame
  def initialize
    update_size(true)
    @offset = 35
    @fps = 20
    @once = true
    @pos = [1,0]
  end
  def draw
    @bg_img_id ||= kitty_graphics_img_load(File.read('./gfx/bg.png'))
    @pipe ||= kitty_graphics_img_load(File.read('./gfx/pipe.png'))
    # pixel_per_cell_y = @size_y.to_f / @rows.to_i
    pixel_per_cell_x = @size_x.to_f / @cols.to_i
    move_cursor(0,0)
    print "hallo welt!"
    kitty_graphics_img_clear(:by_z, -2)
    # (@size_x.to_i/(576/2) + 1).times do |x|
    #   pos_x = (@offset/pixel_per_cell_x).floor + ((576/2)/pixel_per_cell_x.floor).floor*x
    #   move_cursor(x, [pos_x,0].max)
    #   # if pos_x == 0
    #   #   cell_x = 0
    #   #   img_x = 576 - @offset
    #   # else
    #     cell_x = (@offset%pixel_per_cell_x).floor
    #     img_x = 576/2
    #   # end
    #   kitty_graphics_img_display(@bg_img_id, z: -2, cell_x: cell_x, img_x: img_x, width: 576/2) #, columns:@cols, rows:@rows)
    #   # kitty_graphics_img_display(@bg_img_id, z: -2, cell_x: (@offset%pixel_per_cell_x).floor, img_x: 576/2, width: 576/2) #, columns:@cols, rows:@rows)
    # end
    (@size_x.to_i/(576/2) + 1).times do |x|
      kitty_graphics_img_pixel_place(@bg_img_id, @offset + (576/2)*x-1, x*5, z: -2)
    end
    move_cursor(3,0)
    kitty_graphics_img_display(@bg_img_id, z: -2, img_x: 576 - @offset, width: 576/2)
    # if @once
    #   @once = false
      # kitty_graphics_img_clear(:by_z, -1)
      # kitty_graphics_img_pixel_place(@pipe, *@pos.reverse, z: -1)
    # end
    @offset -= 2
    @offset = 576/2 if @offset <= 0
  end
  def input_handler(input)
    case input
    when "\e[A" # up
      @pos[0] -= 1
    when "\e[B" # down
      @pos[0] += 1
    when "\e[D" # left
      @pos[1] -= 1
    when "\e[C" # right
      @pos[1] += 1
    end
  end
end

Bla.new.run
