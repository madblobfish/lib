require 'open3'

KEY_LEFT = 105
KEY_RIGHT = 106

class WeightValues
  attr_accessor :fr, :fl, :br, :bl

  def initialize
    @fr = 0  # Front Right
    @fl = 0  # Front Left
    @br = 0  # Back Right
    @bl = 0  # Back Left
  end
end

def get_weight(weight, code, value)
  case code
  when 0x10 # ABS_HAT0X
    weight.fr = value
  when 0x11 # ABS_HAT0Y
    weight.br = value
  when 0x12 # ABS_HAT1X
    weight.fl = value
  when 0x13 # ABS_HAT1Y
    weight.bl = value
  end

  # Calculate x and y based on weight values
  x = (weight.fr + weight.br) - (weight.fl + weight.bl)
  y = (weight.bl + weight.br) - (weight.fl + weight.fr)
  return weight, x, y
end

def send_key(state, x)
  state_changes = {
    [0, -1] => "#{KEY_LEFT}:1",
    [1, -1] => "#{KEY_RIGHT}:0 #{KEY_LEFT}:1",

    [0, 1]  => "#{KEY_RIGHT}:1",
    [-1, 1] => "#{KEY_LEFT}:0 #{KEY_RIGHT}:1",

    [1, 0]  => "#{KEY_RIGHT}:0",
    [-1, 0] => "#{KEY_LEFT}:0",
  }
  new_state = 0
  new_state = -1 if x <= -2000 # left
  new_state = 1 if x >= 2000 # right
  if cmd = state_changes[[state, new_state]]
    puts cmd
    `ydotool key -d 0 #{cmd}`
  end
  return new_state
end


# Check if the input device path is provided
if ARGV.length < 1
  puts "Missing device path! Specify path. /dev/input/event*"
  return 1
end

InputEvent = Struct.new(:time_sec, :time_usec, :type, :code, :value)
input = File.open(ARGV[0])
state = 0
weight = WeightValues.new
x, y = 0, 0

loop do
  event = InputEvent.new(*input.read(24).unpack("QQSSL"))

  # Process the event if it's an absolute event (EV_ABS)
  if event.type == 3
    weight, x, y = get_weight(weight, x, y, event.code, event.value)
    state = send_key(state, x)
  end
end

input.close
