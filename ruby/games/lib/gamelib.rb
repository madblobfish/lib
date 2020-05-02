
TTY_CLEAN_STATE = `stty -g`
class TerminalGame
  attr_reader :fps, :inited

  def run
    raise 'already started' if @inited
    @inited = true
    raise 'needs a tty' unless STDIN.tty?

    print("\e[?1049h")
    system('stty raw -echo isig')
    STDIN.sync = true

    @fps ||= 0.2

    begin
      thr = Thread.new(abort_on_exception:true) do
        loop do
          get_size()
          draw()
          sleep @fps
        end
      end
      thr.abort_on_exception = true
      loop do
        IO.select([STDIN])
        data = STDIN.read_nonblock(100_000)
        input_handler(data)
      end
    rescue Exception
      return_to_tty()
      raise
    ensure
      return_to_tty()
    end
  end

  def draw
    raise 'Not Implemented'
  end
  def input_handler(data)
    raise 'Not Implemented'
  end

  private
  def get_size
    @rows, @cols = `stty size`.split(' ')
  end
  def return_to_tty
    system('stty '+ TTY_CLEAN_STATE)
    print("\e[?1049l")
  end
end


class Tetris < TerminalGame
  def initialize
    @fps=1
  end
  def draw
    print "\e[2J"
    print "\rXXXX\n"
  end
end

Tetris.new.run
