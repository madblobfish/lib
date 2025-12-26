# key(down|repeat|up) is currently not possibly in terminals
#  a known solution is this but its ugly and non utf8 https://sw.kovidgoyal.net/kitty/protocol-extensions.html#keyboard-handling

TTY_CLEAN_STATE = `stty -g` if STDIN.tty?

class TerminalGameException < StandardError
end
class TerminalGameEnd < TerminalGameException
end

class TerminalGame
  module Term
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
    def cursor_query
      print "\e[6n"
    end
    def size_query
      print "\e[14t"
    end
    def bold(enable = true)
      print bold_code(enable)
    end
    def bold_code(enable = true)
      "\e[#{enable ? '' : '2'}1m"
    end
    def color(color = 15, mode = :fg, &block)
      if block_given?
        return get_color_code(color, mode) + block[] + color_reset_code()
      end
      print get_color_code(color, mode)
    end
    def color_invert
      print color_invert_code
    end
    def color_invert_code
      "\e[7m"
    end
    def color_reset_code
      "\e[0m"
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

    def color_query(color = 11)
      printf "\e]11;?\a"
      # ^[]11;rgb:0000/0000/0000^G
      if /^\e\[\]11;rgb:([0-9a-fA-F]+)\/([0-9a-fA-F]+)\/([0-9a-fA-F]+)\a$/ =~ STDIN.readpartial(200)
        [$1, $2, $3].map{|c| Integer(c, 16) rescue 128 } # sorry if you colors turned grey ;(
      else

      end
    end

    def reset_tty_state
      system('stty '+ TTY_CLEAN_STATE)
    end

    def tty_size_query
      raise "AHHHHHHH" unless STDOUT.ioctl(0x5413, buff="") == 0
      # rows, cols, size_x, size_y =
      buff.unpack("SSSS")
    end

    STRING_TERMINATOR = "\e\\"
    def remove_escape_codes(string)
      string
        .gsub(/\e\[200~(((?!\e\[201~).)+)\e\[201~/,'\1') # Bracketed paste Escapes
        .gsub(/\e\[\d*([;0-9]+)?m/,'') # SGR Escapes
        .gsub(/\eP((?!\e\\).)+\e\\/, '') # DCS Escapes
        .gsub(/\e\^((?!\e\\).)+\e\\/, '') # PM Escapes
        .gsub(/\e_((?!\e\\).)+\e\\/, '') # APC Escapes
        .gsub(/\e\[[\x30-\x3F]*[\x20-\x2F]*[\x40-\x7E]/, '') # CSI Escapes
        .gsub(/\e\]((?!\e\\).)+\e\\/, '') # OSC Escapes
        .gsub(/\e[NO][\x20-\x7F]/,'') # Single Shift Escapes
        .gsub(/\e[\x20-\x2F]+[\x30-\x7E]/, '') # nF Escapes
        .gsub(/[\x00-\x09\x11-\x19]/,'') # C0 control Escapes and other nonprintables
    end

    def _break_lines_mod_string(string)
      def string.hyphens=(hyphens); @hyphens = hyphens; end
      def string.hyphens; @hyphens; end
      def string.badness=(badness); @badness = badness; end
      def string.badness; @badness; end
    end
    def break_lines(string, width, **opts)
      if string.include?("\n\n")
        ret, hyph, bad = string.split("\n\n").map do |s|
          r=break_lines(s, width, **opts);[r, r.hyphens, r.badness]
        end.reduce{|a,b| [a.first+ "\r\n"*2 +b.first, a[1]+b[1], a.last+b.last] }
        _break_lines_mod_string(ret)
        ret.hyphens = hyph
        ret.badness = bad
        return ret
      end

      punctation = opts.fetch(:punctation, /(?:[ .,!—()\n-])/)
      hyphenation = opts.fetch(:hyphenation, true)
      hyphenate_harder = opts.fetch(:hyphenate_harder, false) ? {left: 0, right: 0} : {}
      ignore_whitespace = opts.fetch(:ignore_whitespace, 2)
      badness_window_length = opts.fetch(:ignore_whitespace, 3)

      hyphens = []
      badness = 0
      doover_hyphenate = false
      line = 0
      badness_window = []
      hyph =
        begin
          require 'text/hyphen'
          en = Text::Hyphen.new(**hyphenate_harder)
          raise "nope" unless hyphenation
          lambda{|str, l| en.hyphenate_to(str, l) rescue [nil, str]}
        rescue LoadError, RuntimeError
          lambda{|str, l| [nil, str]}
        end
      out = ''
      rest = string
      current_line = ''
      while not rest.empty?
        start, separator, rest = rest.partition(punctation)
        current_length = remove_escape_codes(current_line+start+separator).length
        if current_length > width + (separator == ' ' ? 1 : 0)
          current_line_space = remove_escape_codes(current_line + separator).length
          space_left = width - current_line_space + (separator == ' ' ? 1 : 0)
          hyphenation = hyph[start, space_left]
          if hyphenation.first && hyphenation.last.length <= width
            out += current_line + hyphenation.first + "\r\n"
            line += 1
            current_line_space += hyphenation.first.length
            current_line = hyphenation.last + separator

            if badness_window.length >= 1
              avg = badness_window.sum.to_f / badness_window.length
              case (diff = [avg, current_line_space].max - [avg, current_line_space].min)
              when 0..1
                badness -= 3
              when 2
                badness -= 1
              when 5...width
                badness += 10
              end
            end
            badness_window.unshift(current_line_space + hyphenation.first.length)
            badness_window = badness_window[..badness_window_length]
            badness += 2
            badness += hyphenation.map{|s| (l = s.chomp('-').length) <= 3 ? 3 * 4-l : 0 }.sum

            hyphens << {original: start, result: hyphenation}
            doover_hyphenate = false
            next
          else # no hyphenation found
            raise TerminalGameException, "not enough space" if current_line == ''
            current_line.chomp!(' ') # eat trailing space
            out += current_line + "\r\n"
            line += 1
            doover_hyphenate = false
            if current_line[-1].match?(punctation) && start == '' && separator == ' '
              separator = '' # cut off spaces following linebreaks and punctation
            end
            current_line = ''

            if badness_window.length >= 1
              avg = badness_window.sum.to_f / badness_window.length
              case [avg, current_line_space].min / [avg, current_line_space].max
              when 0.98..1
                badness -= 2
              when 0.95..1
                badness -= 1
              when 0..0.9
                badness += 10
              end
            end
            badness_window.unshift(current_line_space)
            badness_window = badness_window[..badness_window_length]
            if current_line_space + ignore_whitespace <= width
              badness += width - current_line_space
            end
          end
        end
        if current_line == '' && (start + separator).length >= width && !doover_hyphenate
          rest = start + separator + rest
          doover_hyphenate = true
          hyphens << {result: ['', "doover for hyphenation on line #{line}"]}
          next
        end
        if separator == "\n"
          out += current_line + start + "\r\n"
          line += 1
          current_line = ''
        else
          current_line += start + separator
          # raise TerminalGameException, "not enough space" if width < current_line.length
          hyphens << {result: ['', "not enough space, line #{line}"]} unless current_line.chomp(' ').length <= width
        end
      end
      current_line.chomp!(' ')
      case current_line.length
      when 1..14
        badness += 100
      when (width-ignore_whitespace)..(width)
        # noop :)
      when ([width*0.85, 2].max)..(width-ignore_whitespace)
        badness += 100
      end
      ret = (out+current_line)
      _break_lines_mod_string(ret)
      ret.hyphens = hyphens
      ret.badness = badness
      ret
    end
  end
  include Term
  extend Term

  attr_reader :fps, :sync, :mouse_support, :require_kitty_graphics, :extended_input, :extended_input_implement_ctrl_c
  def inited?
    @inited ||= false
  end

  def run(no_tty = false)
    raise 'already started' if inited?
    Signal.trap("INT"){game_quit(); exit(0)}
    @draw_mutex = Mutex.new

    if @no_tty = no_tty
      # experimental stuff
      @update_size = proc do |initial|
        old = [@rows, @cols, @size_y, @size_x]
        # query char size (rows & cols)
        cursor_save()
        move_cursor(99999,99999)
        cursor_query()
        if /^\e\[(\d+);(\d+)R$/ =~ STDIN.readpartial(200)
          @rows, @cols = [$1, $2]
        end
        # query pixel size
        size_query()
        if /\e\[4;(\d+);(\d+)t\n?/ =~ STDIN.readpartial(200)
          @size_y, @size_x = [$1, $2]
        end
        @size_y, @size_x = [nil]*2
        @size_col, @size_row = [@cols, @rows].zip([@size_x, @size_y]).map{|x,y| y/x.to_f }
        cursor_restore()
        unless true
          size_change_handler() if old != [@rows, @cols, @size_y, @size_x]
        end
      end
    else
      raise 'needs a tty' unless STDIN.tty?
      @update_size = proc do |initial|
        @rows, @cols, @size_x, @size_y = tty_size_query()
        @size_col, @size_row = [@cols, @rows].zip([@size_x, @size_y]).map{|x,y| y/x.to_f }
        size_change_handler() unless initial == true
      end
      Signal.trap("WINCH"){Thread.new{@update_size[]}}
    end
    @inited = true
    @mouse_support = false if @mouse_support.nil?
    @extended_input = false if @extended_input.nil?
    @extended_input_implement_ctrl_c = true if @extended_input_implement_ctrl_c.nil?
    @fps ||= 5
    @show_overflow = false if @show_overflow.nil?

    STDIN.sync = true unless @sync == false
    print("\e[?1049h") # enable alternative screen buffer
    print("\e[?25l") # hide cursor
    @update_size[true]
    print("\e[?7l") unless @show_overflow # hide overflow
    system('stty raw -echo isig') unless @no_tty
    print("\e[?1002h\e[?1006h") if @mouse_support # mouse click/move events
    print("\e[=26u") if @extended_input # keypress in unicode points +types +raw
    raise 'Graphic protocol not supported' if @require_kitty_graphics && !supports_kitty_graphics


    begin
      initial_draw
      if @fps != :manual
        @draw_thread = Thread.new(abort_on_exception:true) do
          loop do
            @update_size[] if false # this needs to be called regulary for non tty operation
            sync_draw{draw()}
            sleep 1.0/@fps
          end
        end
        @draw_thread.abort_on_exception = true
      end
      @read_thread = Thread.new(abort_on_exception:true) do
        loop do
          IO.select([STDIN])
          data = STDIN.read_nonblock(100_000)
          next if data.match(/\e_G/) # ignore graphics stuff for now
          internal_mouse_handler($2,$3,$1,$4) if @mouse_support and data.match(/\e\[\<(\d+);(\d+);(\d+)([Mm])/)
          internal_input_handler(data)
        end
      end
      @read_thread.join
    rescue TerminalGameEnd => e
      return_to_tty()
      puts e.message
      game_exit(e)
    ensure
      return_to_tty()
    end
  end

  # hooks
  def initial_draw
    sync_draw{draw()}
  end
  def game_quit;end
  def game_exit(exception=nil);end
  def draw;end
  KEYBOARD_EVENT_TYPES = {"2"=>:repeat,"3"=>:up}
  KEYBOARD_EVENT_MODIFIERS = {
    shift: 0b1,
    alt: 0b10,
    ctrl: 0b100,
    super: 0b1000,
    hyper: 0b10000,
    meta: 0b100000,
    caps_lock: 0b1000000,
    num_lock: 0b10000000,
  }
  def internal_input_handler(data)
    if @extended_input and /\e\[(?<key_code>\d+)(?:;(?<mod>\d+)?(:(?<type>[123]))?)?(;(?<real_key>\d+))?u/ =~ data
      key = ''<<(real_key || key_code).to_i
      extended_input_handler(
        key,
        KEYBOARD_EVENT_TYPES.fetch(type,:down),
        KEYBOARD_EVENT_MODIFIERS.select{|k,v|((mod.to_i-1)&v) > 0 if mod}.keys
      )
      if @extended_input_implement_ctrl_c and key == 'c' and mod and ((mod.to_i-1) & 0b100) > 0
        exit
      end
    else
      input_handler(data)
    end
  end
  def extended_input_handler(key, state_transition, modifiers=[]);end
  def input_handler(data);end
  def internal_mouse_handler(x, y, button_id, state_transition)
    mouse_handler(x.to_i-1, y.to_i-1, button_id.to_i, (state_transition == 'M' ? :up : :down))
  end
  def mouse_handler(x, y, button_id, state_transition);end
  def size_change_handler;end

  # useful stuff, see also Term module above
  def sync_draw(&block)
    @draw_mutex.synchronize do
      print "\eP=1s\e\\"
      yield
      print "\eP=2s\e\\"
    end
  end

  # kitty_graphics
  def supports_kitty_graphics(used_in_normal_tty = !inited?)
    require 'base64'
    print "\e_Gi=31,s=1,v=1,a=q,t=d,f=24;AAAA\e\\\e[c"
    return false unless STDIN.readpartial(12) == "\e_Gi=31;OK\e\\"
    a = STDIN.readpartial(20)
    return a == "\e[?62;c#{used_in_normal_tty ? "\n" : ''}" || a == "\e[?62;52;c#{used_in_normal_tty ? "\n" : ''}"
  end
  def _kitty_graphics_img_get_id
    raise 'requires @require_kitty_graphics=true' unless require_kitty_graphics
    @kitty_graphics_id ||= 0
    @kitty_graphics_id  += 1
    @kitty_graphics_id
  end
  def kitty_graphics_img_load(png_str, id=_kitty_graphics_img_get_id())
    raise 'requires @require_kitty_graphics=true' unless require_kitty_graphics
    id_string = id.is_a?(Integer) ? ',i=' + id.to_s : ''
    size = 4000
    encoded_img = Base64.encode64(png_str).tr("\n",'')
    if encoded_img.length > size
      enumerator = encoded_img.split('').each_slice(size).map(&:join)
      last = enumerator.pop
      print "\e_Gf=100#{id_string},m=1;#{enumerator.shift}\e\\"
      print *enumerator.map{|e|"\e_Gm=1;#{e}\e\\"}
      print "\e_Gm=0;#{last}\e\\"
    else
      print "\e_Gf=100#{id_string};#{encoded_img}\e\\"
    end
    id
  end
  def kitty_graphics_img_pixel_place_center(id, iw, ih, ow=0, oh=0, w=@size_x, h=@size_y)
    raise 'requires @require_kitty_graphics=true' unless require_kitty_graphics
    kitty_graphics_img_pixel_place(id, (w-iw)/2+ow, (h-ih)/2+oh) #, img_x:iw, img_y:ih)
  end
  def kitty_graphics_img_pixel_place(id, x, y, **opts)
    raise 'requires @require_kitty_graphics=true' unless require_kitty_graphics
    if opts[:place] && opts[:iw] && opts[:ih]
      place = opts.fetch(:place, [0.5, 0.5])
      x = (opts.fetch(:w, @size_x) - opts[:iw]) * place[0]
      y = (opts.fetch(:h, @size_y) - opts[:ih]) * place[1]
      opts.delete(:place)
      opts.delete(:iw)
      opts.delete(:ih)
    end
    # STDERR.puts([id, x,y, opts].to_s)
    # x = 0 if x < 0
    # y = 0 if y < 0
    cursor_save
    pixel_per_cell_x = @size_x.to_f / @cols.to_i
    pixel_per_cell_y = @size_y.to_f / @rows.to_i
    pos_cell_x = (x / pixel_per_cell_x).floor
    pos_cell_y = (y / pixel_per_cell_y).floor
    if pos_cell_x < 0
      pos_cell_x = 0
      opts[:img_x] = x.abs
      # opts[:cell_x] = 0
    else
      # pos_cell_x = @cols if pos_cell_x <= @cols
      opts[:cell_x] = (x % pixel_per_cell_x).floor
    end
    if pos_cell_y < 0
      opts[:img_y] = y.abs
      pos_cell_y = 0
    else
      # pos_cell_y = @rows if pos_cell_y <= @rows
      opts[:cell_y] = (y % pixel_per_cell_y).floor
    end
    # raise [pos_cell_y, pos_cell_x, opts[:cell_y], opts[:cell_x]].inspect
    move_cursor(pos_cell_y, pos_cell_x)
    kitty_graphics_img_display(id, **opts)
    cursor_restore
  end
  def kitty_graphics_img_display(id, **opts)
    raise 'requires @require_kitty_graphics=true' unless require_kitty_graphics
    options = {img_x:0, img_y:0, width:0, height:0, columns:0, rows:0, cell_x:0, cell_y:0, z:0, cursor_move:1}.merge(opts)
    args = {img_x:'x', img_y:'y', width:'w', height:'h', cell_x:'X', cell_y:'Y', columns:'c', rows:'r', z:'z', cursor_move:'C'}
    options.transform_values!{|v| v.to_i}
    raise 'AH' unless id.is_a?(Integer)
    str = '_Ga=p,q=1,i=' + id.to_s
    str += args.map{|k,v| k != :z && options[k] <= 0 ? nil : ",#{v}=#{options[k]}" }.compact.join
    print "\e", str, "\e\\"
    # todo move somewhere else
    # return STDIN.readpartial(200) == "\e_Gi=#{id};OK\e\\"*2
  end
  def kitty_graphics_img_clear(what=:all, *opts)
    raise 'requires @require_kitty_graphics=true' unless require_kitty_graphics
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
    print "\e_Ga=d,q=1,d=#{key}#{args}\e\\"
  end

  private
  def kill_threads
    @draw_thread&.kill
    @read_thread&.kill
  end
  def return_to_tty
    kill_threads
    reset_tty_state unless @no_tty
    kitty_graphics_img_clear if @require_kitty_graphics # clear images on shutdown
    print("\e[=0u") if @extended_input # keypress in unicode points +mod
    print("\e[?1002l\e[?1006l") # disable mouse click/move events
    print("\e[?1049l") # disable alternative screen buffer
    print("\e[?25h") # show cursor
    print("\e[?7h") # show overflow
    print("\eP=2s\e\\") # end synchronized drawing
    STDIN.read_nonblock(100_000) rescue nil # clear stdin buffer
  end
end

# tests for remove_escape_codes
raise "remove_escape_codes selftest fail 1" unless TerminalGame.remove_escape_codes("\x1b[31m\xc2\x9bm") == "\xc2\x9bm" # doesn't parse invalid unicoded escapes
raise "remove_escape_codes selftest fail 2" unless TerminalGame.remove_escape_codes("test0987123 e[m *  \e[38;5;15m") == "test0987123 e[m *  "
raise "remove_escape_codes selftest fail 3" unless TerminalGame.remove_escape_codes("ab\nc") == "ab\nc"
raise "remove_escape_codes selftest fail 3" unless TerminalGame.remove_escape_codes("a\eNbc") == "ac"
raise "remove_escape_codes selftest fail 4" unless TerminalGame.remove_escape_codes("a\x1b[200m\x1b[mb\x1b[5:3;2;4~") == 'ab'
raise "remove_escape_codes selftest fail 5" unless TerminalGame.remove_escape_codes("1\x1b[200~a\x1b[201m\x1b[201~\x1b[x2") == "1a2"
raise "remove_escape_codes selftest fail 6" unless TerminalGame.remove_escape_codes("a\x1bPb\x1b\x1bc\x1b\\d") == 'ad'
raise "remove_escape_codes selftest fail 7" unless TerminalGame.remove_escape_codes("a\x1b_b\x1b\x1b\x1bc\x1b\\d") == 'ad'
raise "remove_escape_codes selftest fail 8" unless TerminalGame.remove_escape_codes("\x1b]X\x07\x1b]X\x1b\x07\x1b\\") == ''

# hyphenation test
# if __FILE__ == $PROGRAM_NAME
#   puts TerminalGame.break_lines(
#     "Sixty-Four comes asking for bread. She folded her handkerchief neatly. The underground bunker was filled with chips and candy. The bees decided to have a mutiny against their queen. There were three sphered rocks congregating in a cubed room. Best friends are like old tomatoes and shoelaces. Baby wipes are made of chocolate stardust. The rain pelted the windshield as the darkness engulfed us.\r\n\r\nSomething split up at the end",
#     ARGV.first.to_i
#   ).split("\r\n").map{|s| "#{s.inspect} (#{s.length})" }
# end
