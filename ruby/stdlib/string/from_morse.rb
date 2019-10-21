require_relative 'to_morse.rb'
class String
  def from_morse
    self.split(' ').map{|e| MORSE_CODES.detect(lambda{["\u{fffd}"]}){|k,v| e == v}.first }.join('')
  end
end

if __FILE__ == $PROGRAM_NAME
  if ARGV.empty?
    puts $PROGRAM_NAME + ' <string>'
    puts 'converts morse code into normal strings.'
    exit
  end
  puts ARGV.join(' ').from_morse
end
