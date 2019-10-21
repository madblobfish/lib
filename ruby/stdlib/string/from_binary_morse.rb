require_relative 'from_binary_morse_to_morse.rb'
require_relative 'from_morse.rb'
class String
  def from_binary_morse
    self.from_binary_morse_to_morse.from_morse
  end
end

if __FILE__ == $PROGRAM_NAME
  unless ARGV.one?
    puts $PROGRAM_NAME + ' <ones and zeors>'
    puts 'decodes binary morse.'
    exit
  end
  puts ARGV.first.from_binary_morse
end
