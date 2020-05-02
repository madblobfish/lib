def DbusEvent(watch_expression)
  raise 'needs block' unless block_given?
  require 'open3'
  Open3.popen3("dbus-monitor #{watch_expression}") do |i,o,e,t|
    i.close
    IO.select([o])
    o.read_nonblock(30000)
    while true
      IO.select([o])
      read = o.read_nonblock(30000)
      Thread.new{yield(read)}
    end
  end
end
