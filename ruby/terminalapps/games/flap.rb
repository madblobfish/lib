require_relative '../lib/gamelib.rb'

class BirdGame < TerminalGame
  BG_HEIGHT = 576
  def initialize
    @require_kitty_graphics = true
    @timer = 0
    @points = 0
    @movespeed = 3
    @offset = 35
    @fps = 20
    @bird = {pos: [50, BG_HEIGHT/4], yspeed: -5, imgs: [], size: [30,24]}
    @pipe_size = [52, 320]
    @objects = []
    @nextspawn = 0
    @bg_colors = [[94,226,112],[0,163,0]]
    @passing = false
  end
  def initial_draw
    raise 'window not wide enough' if @size_x <= 250
    raise 'window not high enough' if @size_y <= 440
    daytime = (7..21).include?(Time.now.hour)
    # background color, not resize safe (otherwise it would output a lot of stuff)
    # color(@bg_colors[daytime ? 0 : 1], :bg)
    # print((' '*@size_x + "\r\n")*@size_y)
    @bg_img_id = kitty_graphics_img_load(File.read("./gfx/bg#{!daytime ? '-night' : ''}.png"))
    @pipe = kitty_graphics_img_load(File.read('./gfx/pipe.png'))
    @pipe_top = kitty_graphics_img_load(File.read('./gfx/pipe-top.png'))
    @bird[:imgs] = 3.times.map{|x|kitty_graphics_img_load(File.read("./gfx/b#{x+1}.png"))}
    draw
  end
  def loose(reason)
    raise TerminalGameEnd, "you lost: #{reason}, #{@points}p - #{@timer/@fps}s"
  end
  def check_loose
    loose('YU DED') if @bird[:pos][1] > 500 || @bird[:pos][1] < -10
    # collisions
    passing_this_loop = false
    @objects.select{|o|o[:background]}.any? do |o|
      if @bird[:pos][0] + @bird[:size][0] >= o[:x] && o[:x] + @pipe_size[0] >= @bird[:pos][0] + 3
        passing_this_loop = true
        if o[:img_id] == @pipe_top
          loose('hit your head') if @bird[:pos][1] + 7 <= @pipe_size[1] + o[:y]
        else
          loose('hit your foot') if @bird[:pos][1] + @bird[:size][1] >= o[:y] + 7
        end
      end
    end
    if @passing
      unless passing_this_loop
        @passing = false
        @points += 1
      end
    else
      @passing = passing_this_loop
    end
  end
  def draw(thing=true)
    pixel_per_cell_x = @size_x.to_f / @cols.to_i
    move_cursor(0,0)
    print "you surived #{@points} pipes, #{@timer/@fps}s"
    # bg
    kitty_graphics_img_clear(:by_z, -2)
    (@size_x.to_i/(BG_HEIGHT/2) + 1).times do |x|
      kitty_graphics_img_pixel_place(@bg_img_id, @offset + (BG_HEIGHT/2)*x-1, 0, z: -2, width: BG_HEIGHT/2)
    end
    move_cursor(0,0)
    kitty_graphics_img_display(@bg_img_id, z: -2, img_x: BG_HEIGHT/2 - @offset, width: BG_HEIGHT/2*0 +@offset)
    # pipes
    if @timer >= @nextspawn
      @objects << {img_id: @pipe, x: @size_x.to_i, y: rand(200..400), background: true}
      yoffset = rand(408..500)
      @objects << {img_id: @pipe_top, x: @size_x.to_i, yoffset: yoffset, y: @objects.last[:y] - yoffset, background: true}
      @nextspawn = @timer + rand(50..150)
    end
    @objects.map{|x|x[:img_id]}.uniq.each{|id| kitty_graphics_img_clear(:id, id)}
    @objects.each do |obj|
      kitty_graphics_img_pixel_place(obj[:img_id], obj[:x], obj[:y], width: obj.fetch(:width,0), height: obj.fetch(:height,0), z: obj.fetch(:z, 0))
      obj[:x] -= @movespeed if obj.has_key?(:background)
    end
    @objects.reject!{|obj| obj[:x] + obj.fetch(:width, 1000) <= 0}
    # bird
    kitty_graphics_img_clear(:id, @bird[:imgs].first)
    @bird[:imgs].rotate! if @timer % 5 == 0
    kitty_graphics_img_pixel_place(@bird[:imgs].first, *@bird[:pos], z: -1)

    check_loose()
    @bird[:yspeed] = [@bird[:yspeed] + 2.6, 27].min
    @bird[:pos][1] += @bird[:yspeed] if thing

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

BirdGame.new.run
