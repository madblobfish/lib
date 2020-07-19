TTY_CLEAN_STATE = `stty -g`
class TerminalGame
  attr_reader :fps, :inited, :sync, :mouse_support

  def run
    raise 'already started' if @inited
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

    begin
      initial_draw
      if @fps != :manual
        thr = Thread.new(abort_on_exception:true) do
          loop do
            update_size()
            draw()
            sleep 1.0/@fps
          end
        end
        thr.abort_on_exception = true
      end
      loop do
        IO.select([STDIN])
        data = STDIN.read_nonblock(100_000)
        internal_mouse_handler($2,$3,$1,$4) if @mouse_support and data.match(/\e\[\<(\d+);(\d+);(\d+)([Mm])/)
        input_handler(data)
      end
    rescue Exception
      return_to_tty()
      raise
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
    system('stty '+ TTY_CLEAN_STATE)
    print("\e[?1002l\e[?1006l") # disable mouse click/move events
    print("\e[?1049l") # disable alternative screen buffer
    print("\e[?25h") # show cursor
    print("\e[?7h") # show overflow
  end
  def clear
    print "\e[2J"
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
end
