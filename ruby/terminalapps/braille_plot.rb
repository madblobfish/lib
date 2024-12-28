require_relative 'lib/gamelib'

BRAILLE_POS = {
  [0,0] => 0b00000001,
  [0,1] => 0b00000010,
  [0,2] => 0b00000100,
  [1,0] => 0b00001000,
  [1,1] => 0b00010000,
  [1,2] => 0b00100000,
  [0,3] => 0b01000000,
  [1,3] => 0b10000000,
}

def braille_set_pixel(*pos)
  base = 10240
  (base + pos.uniq.map{|p| BRAILLE_POS.fetch(p, 0)}.sum).chr('UTF-8')
end

def braille_render(dots, size)
  (size.last/4).ceil.times.map do |y|
    (size.first/2).ceil.times.map do |x|
      braille_set_pixel(*BRAILLE_POS.keys.select do |p|
        dots[[x*2 + p.first, y*4 + p.last]]
      end)
    end.join('')
  end.reverse.join("\n")
end

def braille_plot_timeseries(values, timestamps=nil)
  timestamps ||= Array.new(values.length){|i| i}
  raise 'values length != timestamps.length' unless values.length == timestamps.length
  size = [
    values.length,
    (values.max - values.min).ceil,
  ]
  max_size = [192*2, 56*4]
  scaling_factors = size.zip(max_size).map{|s,m| (v = m.to_f/s) >= 1 ? 1 : v }
  a = braille_render(Hash[values.each_with_index.map{|e,i| [[timestamps[i],(e-values.min)].zip(scaling_factors).map{|v,sf| sf*v}.map(&:to_i), 1]}], max_size.map(&:to_i))
end

if __FILE__ == $PROGRAM_NAME
  raise 'gimme exactly one file' unless ARGV.one?
  # puts braille_plot_timeseries(1.upto(ARGV.first.to_i).to_a.reverse + 1.upto(ARGV.first.to_i).to_a)
  # puts braille_plot_timeseries(50.times.map{|i| 100} + 50.times.map{|i| 20} + 284.times.map{|i| 3})
  values = File.read(ARGV.first).split("\n").map(&:to_i)
  puts values.max.to_s.center(192)
  puts braille_plot_timeseries(values)
  puts values.min.to_s.center(192)
end
