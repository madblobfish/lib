class String
  def from_binary_morse_to_morse
    self.gsub('111', '-').gsub('1', '.').gsub('0000000', '  ').gsub('000', ' ').gsub('0', '')
  end
end

if __FILE__ == $PROGRAM_NAME
  unless ARGV.one?
    puts $PROGRAM_NAME + ' <ones and zeors>'
    puts 'decodes binary morse encoded strings back into morse code.'
    exit
  end
  puts ARGV.first.from_binary_morse_to_morse
end
