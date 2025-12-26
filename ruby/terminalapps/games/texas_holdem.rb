class Card
  include Comparable
  CARDS = {
    spade: "🂢🂣🂤🂥🂦🂧🂨🂩🂪🂫🂭🂮🂡",
    heart: "🂲🂳🂴🂵🂶🂷🂸🂹🂺🂻🂽🂾🂱",
    diamond: "🃂🃃🃄🃅🃆🃇🃈🃉🃊🃋🃍🃎🃁",
    club: "🃒🃓🃔🃕🃖🃗🃘🃙🃚🃛🃝🃞🃑",
  }
  ALL_CARDS = CARDS.values.join.split('')
  attr :suit, :rank
  def initialize(symbol)
    @symbol = symbol
    idx = nil
    if (suite, _ = CARDS.detect{|n, cards| idx = cards.index(symbol)})
      @suit = suite
      @rank = idx
    else
      raise "AH"
    end
  end
  def self.sample(n=1)
    ALL_CARDS.sample(n).map{|c|Card.new(c)}
  end
  def <=>(other)
    @rank <=> other.rank
  end
  def eql?(other)
    @rank == other.rank && @suit == other.suit
  end
  def self.back
    "🂠"
  end
  def to_s
    @symbol
  end
end

class Hand
  include Comparable
  RANKS = [
    :highcard, :pair, :two_pairs, :three_of_a_kind,
    :straight, :flush, :full_house, :four_of_a_kind,
    :straight_flush, :royal_flush
  ]
  attr :complete, :cards, :rank, :special_cards
  def self.from_string(cards)
    Hand.new(cards.split('').map{|c| Card.new(c)})
  end
  def initialize(*cards)
    cards = cards.first if cards.one? && cards.first.is_a?(Array)
    @cards = cards
    case cards.length
    when 1...5
      @complete = false
    when 5
      @complete = true
    else
      raise "this is no valid hand"
    end
    @special_cards = {}

    @rank = :highcard
    ranked = cards.group_by(&:rank).select{|r, v| v.length >= 2}
    if ranked.length >= 1
      if quads = ranked.detect{|k, v| v.length == 4}&.last
        @special_cards[:quads] = quads
        @rank = :four_of_a_kind
      elsif trips = ranked.detect{|k, v| v.length == 3}&.last
        @special_cards[:trips] = trips
        if dubs = (cards - trips).group_by(&:rank).detect{|k, v| v.length >= 2}&.last
          @special_cards[:dubs] = dubs
          @rank = :full_house
        else
          @rank = :three_of_a_kind
        end
      elsif ranked.length >= 2
        @special_cards[:dubs], @special_cards[:double_dubs] = ranked.values.sort_by(&:first)
        @rank = :two_pairs
      else
        @special_cards[:dubs] = ranked.values.first
        @rank = :pair
      end
    end

    possible_straight_flush = cards.group_by(&:rank).keys.sort.chunk_while{|i, j| i+1 != j}.any?{|c| c.length >= 5}
    if possible_straight_flush
      unless RANKS.index(@rank) >= 3
        @rank = :straight
      end
    end

    if cards.group_by{|card| Card::CARDS.detect{|k,v| v.include?(card.to_s)}.first}.any?{|s,c| c.length >= 5}
      if possible_straight_flush
        if cards.sort.last.rank == 12 
          @rank = :royal_flush
        else
          @rank = :straight_flush
        end
      else
        @rank = :flush
      end
    end
  end
  def <=>(other)
    rindex = RANKS.index(@rank) <=> RANKS.index(other.rank)
    return rindex unless rindex == 0
    case @rank
    when :highcard, :straight, :flush, :straight_flush, :royal_flush
      @cards.sort.zip(other.cards.sort).reverse.detect do |a, b|
        return a.rank <=> b.rank unless a.rank == b.rank
      end
      return 0
    when :pair
      res = @special_cards[:dubs].first <=> other.special_cards[:dubs].first
      return res unless res == 0
      return Hand.new(@cards - @special_cards[:dubs]) <=> Hand.new(other.cards - other.special_cards[:dubs])
    when :two_pairs
      res = @special_cards[:double_dubs].first <=> other.special_cards[:double_dubs].first
      return res unless res == 0
      return Hand.new(@cards - @special_cards[:double_dubs]) <=> Hand.new(other.cards - other.special_cards[:double_dubs])
    when :three_of_a_kind, :full_house
      res = @special_cards[:trips].first <=> other.special_cards[:trips].first
      return res unless res == 0
      return Hand.new(@cards - @special_cards[:trips]) <=> Hand.new(other.cards - other.special_cards[:trips])
    when :four_of_a_kind
      res = @special_cards[:quads].first <=> other.special_cards[:quads].first
      return res unless res == 0
      return (@cards - @special_cards[:quads]).first <=> (other.cards - other.special_cards[:quads]).first
    else
      raise "unknown rank"
    end
  end
  def self.random
    Hand.new(Card.sample(5))
  end
  def inspect
    "#<Hand: @complete=#{@complete} @cards=#{@cards.sort.map(&:to_s).join} @rank=#{@rank}>"
  end
end

class RealHand
  include Comparable
  attr :cards, :hand
  def initialize(*cards)
    @cards = cards.first if cards.one? #&& community_cards.first.is_a?(Array)
    build_hand
  end
  def add_card(*more_cards)
    more_cards = more_cards.first if more_cards.one? && more_cards.first.is_a?(Array)
    @cards += more_cards
    build_hand
  end
  def self.random
    RealHand.new(Card.sample(7))
  end
  def <=>(other)
    hand <=> other.hand
  end
  def rank
    hand.rank
  end
  def inspect
    "#<Hand: #{rank} #{cards.sort.map(&:to_s).join()}>"
    "#<Hand: #{rank} #{hand.cards.sort.map(&:to_s).join(' ')} " +
      (remainder.any? ? " (#{remainder.sort.map(&:to_s).join(' ')} )" : '') + '>'
  end
  def remainder
    cards - hand.cards
  end
  private
  def build_hand
    if cards.length > 5
      @hand = cards.combination(5).map{|e| Hand.new(e)}.max
    else
      @hand = Hand.new(cards)
    end
  end
end

class TexasHoldemRound
  def initialize(big_blind, players)
    @card_deck = Card::ALL_CARDS.shuffle
    @options = options
    players.length
    @community_cards = []
    @last_bet_inc = 0

  end
  def bet(value)
  end
  def call(value)
  end
  def check(value)
  end
  def quit
  end
  def inspect
     "community_cards=#{@community_cards.join}"
  end
  def to_s(player_view=-1)
    "community"
    players.each do |p|
      p
    end
  end
end

class TexasHoldem
  THING = {
    a: [20, 50, 100, 200, 400, 800, 1600],
    b: [30, 50, 80, 150, 300, 500, 1000],
  }
  DEFAULT_OPTS = {
    big_blind_inc_time: 20 * 60, # 20m
    thing: THING[:a]
  }
  def initialize(players = 2, **opts)
    @start_time = Time.now
    @options = DEFAULT_OPTS.merge(opts)
    @players = Array.new(players){}
    @round_num = 0
    @bets = []
  end
  def big_blind
    @options[:thing][0..((Time.now - @start_time) / @options[:big_blind_inc_time]).floor].last
  end
  def round
    @round = TexasHoldemRound.new(big_blind, @players.rotate(@round_num))
  end
  def inspect
    "#<TexasHold'em: players_count=#{@players.length}>"
  end
  def to_s(player_view = -1)

  end
end

# th = TexasHoldem.new
# puts th.inspect
# puts th.big_blind
# Card::ALL_CARDS.combination(5).lazy.map{|cds|Hand.new(cds.map{|c|Card.new(c)}).rank}.group_by{|x|x}.transform_values(&:count)
#=> {flush: 4644, pair: 1098240, highcard: 1184220, two_pairs: 123552, three_of_a_kind: 54912, full_house: 3744, four_of_a_kind: 624, straight_flush: 224, royal_flush: 280, straight: 128520}
#  straight_flush: 0.008618832148243914
#  royal_flush: 0.010773540185304891
#  four_of_a_kind: 0.024009603841536616
#  full_house: 0.14405762304921968
#  flush: 0.17868685935912829
#  three_of_a_kind: 2.112845138055222
#  two_pairs: 4.75390156062425
#  straight: 4.945054945054945
#  pair: 42.25690276110444
#  highcard: 45.56514913657771


num = 3
cards = Card.sample(num*2 + 5)
players = num.times.map{RealHand.new(cards.pop(2))}
players.map{|player| p player}
cards.each do |c|
  readline
  puts "pulling a #{c} "
  players.each{|p| p.add_card(c)}
  players.map{|player| p player}
end
win = players.max
puts '', "we got a winner: player #{players.find_index(win)}"
p win
