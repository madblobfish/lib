require_relative 'to_morse.rb'

class String
  def to_binary_morse
    self.to_morse.each_char.map do |chr|
      {'.': '1', '-': '111', ' ': '000'}[chr.to_sym]
    end.join('0')
  end
end

if __FILE__ == $PROGRAM_NAME
  if ARGV.empty?
    puts $PROGRAM_NAME + ' <string>'
    puts 'converts strings into binary encoded morse codes.'
    exit
  end
  puts ARGV.join(' ').to_binary_morse
end
