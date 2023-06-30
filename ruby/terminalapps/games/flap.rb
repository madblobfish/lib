require_relative '../lib/gamelib.rb'

class Bla < TerminalGame
  BG_HEIGHT = 576
  def initialize
    @require_kitty_graphics = true
    @timer = 0
    @movespeed = 3
    @offset = 35
    @fps = 20
    @bird = {pos: [50, BG_HEIGHT/2], yspeed: -5, imgs: []}
    @objects = []
    @spawnrate = 70
  end
  def initial_draw
    @bg_img_id = kitty_graphics_img_load(File.read('./gfx/bg.png'))
    @pipe = kitty_graphics_img_load(File.read('./gfx/pipe.png'))
    @bird[:imgs] = 3.times.map{|x|kitty_graphics_img_load(File.read("./gfx/b#{x+1}.png"))}
    draw
  end
  def draw
    pixel_per_cell_x = @size_x.to_f / @cols.to_i
    move_cursor(0,0)
    print "hallo welt! #{@timer/@fps}"
    # bg
    kitty_graphics_img_clear(:by_z, -2)
    (@size_x.to_i/(BG_HEIGHT/2) + 1).times do |x|
      kitty_graphics_img_pixel_place(@bg_img_id, @offset + (BG_HEIGHT/2)*x-1, 0, z: -2, width: BG_HEIGHT/2)
    end
    move_cursor(0,0)
    kitty_graphics_img_display(@bg_img_id, z: -2, img_x: BG_HEIGHT/2 - @offset, width: BG_HEIGHT/2*0 +@offset)
    # pipes
    if @timer % @spawnrate == 0
      @objects << {img_id: @pipe, x: @size_x.to_i, y: rand(200..400), background: true}
      @objects << {img_id: @pipe, x: @size_x.to_i, y: @objects.last[:y] - 100, background: true}
    end
    @objects.map{|x|x[:img_id]}.uniq.each{|id| kitty_graphics_img_clear(:id, id)}
    @objects.each do |obj|
      kitty_graphics_img_pixel_place(obj[:img_id], obj[:x], obj[:y], width: obj.fetch(:width,0), height: obj.fetch(:height,0), z: obj.fetch(:z, 0))
      obj[:x] -= @movespeed if obj.has_key?(:background)
    end
    @objects.reject!{|obj| obj[:x] + obj.fetch(:width, 1000) <= 0}
    # bird
    kitty_graphics_img_clear(:id, @bird[:imgs].first)
    @bird[:imgs].rotate! if @timer % 4 == 0
    kitty_graphics_img_pixel_place(@bird[:imgs].first, *@bird[:pos], z: -1)

    raise "YU DED" if @bird[:pos][1] > 500 || @bird[:pos][1] < 0
    @bird[:yspeed] = [@bird[:yspeed] + 2.6, 27].min
    @bird[:pos][1] += @bird[:yspeed]

    @timer += 1
    @offset -= @movespeed
    @offset = BG_HEIGHT/2 if @offset <= 0
  end
  def input_handler(input)
    case input
    when "\e[A", " " # up
      @bird[:yspeed] = -19
    end
  end
end

Bla.new.run
