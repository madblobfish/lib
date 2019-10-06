require_relative 'dbus_event.rb'
DbusEvent('interface=\'org.freedesktop.Notifications\',member=\'Notify\'') do |evt|
  [1,0].cycle(21) do |n|
    sleep(0.2)
    File.write('/sys/class/leds/input2::capslock/brightness', n)
  end
end
