require 'openssl'

def raffle(names, lots)
  h = lambda{|seed, data| OpenSSL::HMAC.hexdigest("SHA256", seed, data)}
  seed = h["fixed-pre-seed", names.sort.join("\n").downcase]
  names.sort_by{|n| h[seed, n]}.take(lots)
end

if __FILE__ == $PROGRAM_NAME
  if ARGV.length < 2 || ARGV.include?('--help') || ARGV.include?('-h')
    puts 'raffle.rb Number people.txt [people.txt]'
    puts 'this eats one or more files with names and raffles among them Number lots'
  end
  lots = Integer(ARGV.shift, 10)
  puts raffle(ARGF.readlines, lots)
end
