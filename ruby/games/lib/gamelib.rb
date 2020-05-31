
TTY_CLEAN_STATE = `stty -g`
class TerminalGame
  attr_reader :fps, :inited

  def run
    raise 'already started' if @inited
    @inited = true
    raise 'needs a tty' unless STDIN.tty?
#    raise 'needs to implement draw'

    STDIN.sync = true
    print("\e[?1049h")
    print("\e[?25l")
    system('stty raw -echo isig')

    @fps ||= 0.2

    begin
      if @fps != :manual
        thr = Thread.new(abort_on_exception:true) do
          loop do
            update_size()
            draw()
            sleep @fps
          end
        end
        thr.abort_on_exception = true
      end
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
  def update_size
    @rows, @cols = `stty size`.split(' ')
  end
  def return_to_tty
    system('stty '+ TTY_CLEAN_STATE)
    print("\e[?1049l")
  end
  def clear
    print "\e[2J"
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

Tetris.new.run if __FILE__ == $PROGRAM_NAME
