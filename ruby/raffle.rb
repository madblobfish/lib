
require 'openssl'

def raffle(names, lots_amount)
  raise "doesn't work that way" if names.length <= lots_amount || lots_amount <= 0
  h = lambda{|seed, data| Integer(OpenSSL::HMAC.hexdigest("SHA256", seed, data).unpack1('h*'), 10) }

  seed = h["fixed-seed", names.join("\n")].to_s
  people_lots = names.map{|p| [p, h[seed, p]]}
  winners = []
  lots_amount.times.each do |l|
    winner = people_lots.sort_by{|p| (h[seed, l.to_s] - p[1]).abs}.first
    winners << winner.first
    people_lots.delete(winner)
  end
  winners
end

if __FILE__ == $PROGRAM_NAME
  if ARGV.length < 2 || ARGV.include?('--help') || ARGV.include?('-h')
    puts 'raffle.rb Number people.txt [people.txt]'
    puts 'this eats one or more files with names and raffles among them Number lots'
  end
  lots = Integer(ARGV.shift, 10)
  puts raffle(ARGF.readlines, lots)
end
