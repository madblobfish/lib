TTY_CLEAN_STATE = `stty -g`
class TerminalGame
  attr_reader :fps, :sync, :mouse_support, :require_kitty_graphics
  def inited
    @inited ||= false
  end

  def run
    raise 'already started' if inited
    raise 'needs a tty' unless STDIN.tty?

    @inited = true
    @mouse_support = false if @mouse_support.nil?
    @fps ||= 5

    STDIN.sync = true unless @sync == false
    print("\e[?1049h") # enable alternative screen buffer
    print("\e[?25l") # hide cursor
    print("\e[?7l") # hide overflow
    system('stty raw -echo isig')
    print("\e[?1002h\e[?1006h") if @mouse_support # mouse click/move events
    raise 'Graphic protocoll not supported' if @require_kitty_graphics && !supports_kitty_graphics
    if true # might not need this sometimes
      print "\e[14t"
      if /\e\[4;(\d+);(\d+)t\n?/ =~ STDIN.readpartial(200)
        @size_y, @size_x = [$1, $2]
      end
    end
    update_size()

    begin
      initial_draw
      if @fps != :manual
        @draw_thread = Thread.new(abort_on_exception:true) do
          loop do
            update_size()
            draw()
            sleep 1.0/@fps
          end
        end
        @draw_thread.abort_on_exception = true
      end
      loop do
        IO.select([STDIN])
        data = STDIN.read_nonblock(100_000)
        next if data.match(/\e_G/) # ignore graphics stuff for now
        internal_mouse_handler($2,$3,$1,$4) if @mouse_support and data.match(/\e\[\<(\d+);(\d+);(\d+)([Mm])/)
        input_handler(data)
      end
    ensure
      return_to_tty()
    end
  end

  def initial_draw
    draw
  end
  def draw;end
  def input_handler(data);end
  def internal_mouse_handler(x, y, button_id, state_transition)
    mouse_handler(x.to_i-1, y.to_i-1, button_id.to_i, (state_transition == 'M' ? :up : :down))
  end
  def mouse_handler(x, y, button_id, state_transition);end

  private
  def update_size
    @rows, @cols = `stty size`.split(' ')
  end
  def return_to_tty
    @draw_thread.kill
    system('stty '+ TTY_CLEAN_STATE)
    print("\e[?1002l\e[?1006l") # disable mouse click/move events
    print("\e[?1049l") # disable alternative screen buffer
    print("\e[?25h") # show cursor
    print("\e[?7h") # show overflow
    STDIN.read_nonblock(100_000) rescue nil # clear stdin buffer
  end
  def clear
    print "\e[2J"
  end
  def cursor_save
    print "\e[s"
  end
  def cursor_restore
    print "\e[u"
  end
  def move_cursor(x = 0, y = 0)
    print "\e[#{x+1};#{y+1}H"
  end
  def color(color = 15, mode = :fg)
    print get_color_code(color, mode)
  end
  def get_color_code(color = 15, mode = :fg)
    code = {fg: 38, bg: 48}[mode]
    raise 'invalid color mode' if code.nil?
    if color.is_a? Integer
      "\e[#{code};5;#{color.to_i}m"
    elsif color&.length == 3
      "\e[#{code};2;#{color.map(&:to_i).join(';')}m"
    else
      raise 'color can be int between 0 and 255 or array with 3 ints [r,g,b]'
    end
  end

  # kitty_graphics
  def supports_kitty_graphics(used_in_normal_tty = !inited)
    print "\e_Gi=31,s=1,v=1,a=q,t=d,f=24;\0\0\0\e\\\e[c"
    return STDIN.readpartial(20) == "\e[?62;c#{used_in_normal_tty ? "\n" : ''}"
  end
  def _kitty_graphics_img_get_id
    @kitty_graphics_id ||= 0
    @kitty_graphics_id  += 1
    @kitty_graphics_id
  end
  def kitty_graphics_img_load(png_str, id=_kitty_graphics_img_get_id())
    id_string = id.is_a?(Integer) ? ',i=' + id.to_s : ''
    size = 4000
    require 'base64'
    encoded_img = Base64.encode64(png_str).tr("\n",'')
    if encoded_img.length > size
      first = true
      enumerator = encoded_img.split('').each_slice(size).map(&:join)
      last = enumerator.pop
      print *enumerator.map{|e|"\e_G#{first ? (first = false;"f=100#{id_string},") : ''}m=1;#{e}\e\\"}
      print "\e_Gm=0;#{last}\e\\"
    else
      print "\e_Gf=100#{id_string};#{encoded_img}\e\\"
    end
    id
  end
  def kitty_graphics_img_pixel_place(id, x, y, **opts)
    cursor_save
    pixel_per_cell_x = @size_x.to_f / @cols.to_i
    pixel_per_cell_y = @size_y.to_f / @rows.to_i
    pos_cell_x = (x / pixel_per_cell_x).floor
    pos_cell_y = (y / pixel_per_cell_y).floor
    if pos_cell_x < 0
      pos_cell_x = 0
      opts[:img_x] += x.abs
      opts[:cell_x] = 0
    else
      # pos_cell_x = @cols if pos_cell_x <= @cols
      opts[:cell_x] = (x % pixel_per_cell_x).floor
    end
    if pos_cell_y < 0
      pos_cell_y = 0
      opts[:img_y] += y.abs
      opts[:cell_y] = 0
    else
      # pos_cell_y = @rows if pos_cell_y <= @rows
      opts[:cell_y] = (y % pixel_per_cell_y).floor
    end
    move_cursor(pos_cell_y, pos_cell_x)
    kitty_graphics_img_display(id, **opts)
    cursor_restore
  end
  def kitty_graphics_img_display(id, **opts)
    options = {img_x:0, img_y:0, width:0, height:0, columns:0, rows:0, cell_x:0, cell_y:0, z:0}.merge(opts)
    args = {img_x:'x', img_y:'y', width:'w', height:'h', cell_x:'X', cell_y:'Y', columns:'c', rows:'r', z:'z'}
    raise 'AH' unless id.is_a?(Integer)
    str = '_Ga=p,i=' + id.to_s
    str += args.map{|k,v| k != :z && options[k] <= 0 ? nil : ",#{v}=#{options[k]}" }.compact.join
    print "\e", str, "\e\\"
    # todo move somewhere else
    # return STDIN.readpartial(200) == "\e_Gi=#{id};OK\e\\"*2
  end

  def kitty_graphics_img_clear(what=:all, *opts)
    keep = true # for now lets not make this configureable
    key = {
      all: 'a',
      id: 'i',
      under_cursor: 'c',
      by_cell: 'p',
      by_cell_z: 'q',
      by_column: 'x',
      by_row: 'y',
      by_z: 'z',
    }[what]
    args = case what
      when :id, :by_column, :by_row, :by_z
        raise 'Ah' unless opts.first.is_a?(Integer)
        ",#{key}=" + opts.first.to_s
      when :by_cell
        raise 'ah' unless opts.take(2).all?{|x|x.is_a?(Integer)}
        %w(,x= ,y=).zip(opts.take(2)).map(&:join).join
      when :by_cell_z
        raise 'ah' unless opts.take(3).all?{|x|x.is_a?(Integer)}
        %w(,x= ,y= ,z=).zip(opts.take(3)).map(&:join).join
      else
        ''
      end
    key.upcase! unless keep
    print "\e_Ga=d,d=#{key}#{args}\e\\"
  end
end
