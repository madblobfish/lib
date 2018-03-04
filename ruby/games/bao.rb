# see https://en.wikipedia.org/wiki/Bao_(mancala_game)

module SymbolExt
  refine Symbol do
    def +(other)
      return other.+(self) unless other.class == Symbol
      self.to_s + other.to_s
    end
  end
  refine TrueClass do
    def to_i
      1
    end
  end
  refine FalseClass do
    def to_i
      0
    end
  end
end

class BaoError < StandardError;end
class GameOver < BaoError;end
class InvalidMove < BaoError;end
class ImplementationError < BaoError;end

class Bao
  using SymbolExt
  def initialize
    @players = [:l, :r]
    @board_size_half = 8
    @board_size = 2*@board_size_half
    @board = {l: Array.new(@board_size, 0), r: Array.new(@board_size, 0)}
    @marbels = Hash.new(@board_size*2 - 10)
    @board[:l][4 -1] = @board[:r][4 -1] = 6
    @board[:l][3 -1] = @board[:r][3 -1] = 2
    @board[:l][2 -1] = @board[:r][2 -1] = 2
    @active_player = :l
    @taken_marbels = 0
    @eaten_marbels = 0
    @firstmove = true
  end
  # def initialize_copy(other)
  #   @board[:l] = other.instance_variable_get("@board")[:l].dup
  #   @board[:r] = other.instance_variable_get("@board")[:r].dup
  #   @marbels[:l] = other.instance_variable_get("@marbels")[:l].dup
  #   @marbels[:r] = other.instance_variable_get("@marbels")[:r].dup
  # end

  def move(num)
    raise InvalidMove, "move is outside board size (0 - #{@board_size-1})" unless (0...@board_size).include?(num)
    @taken_marbels += @board[@active_player][num]
    raise InvalidMove.new("no marbles there") if @taken_marbels == 0
    @board[@active_player][num] = 0

    # took_marble_from_hand = false
    if @firstmove
      if @marbels[@active_player] > 0
        # took_marble_from_hand = true
        @marbels[@active_player] -= 1
        @taken_marbels += 1
      end
      @eaten_marbels = 0
    end

    @taken_marbels.times do |i|
      @board[@active_player][(num+i+1) % @board_size] += 1
    end
    @firstmove = false

    last_step = (num+@taken_marbels) % @board_size
    @taken_marbels = 0
    other_player = other_player()
    if @board[@active_player][last_step] > 1
      if last_step < @board_size_half
        take_from = last_step
        take_from = @board_size_half-1 -last_step if other_player == :r
        @eaten_marbels += @board[other_player][take_from]
        @taken_marbels += @board[other_player][take_from]
        @board[other_player][take_from] = 0
      end
      move(last_step)
    end

    @active_player = other_player
    @firstmove = true

    check_win()
    self
  end
  alias_method :m, :move

  def check_win()
    if @board[:l][0, 8].sum == 0
      raise GameOver.new("r won")
    elsif @board[:r][0, 8].sum == 0
      raise GameOver.new("l won")
    end
    false
  end

  def inspect
    ret = "\n" << @board[:l][8, 15].reverse!.inspect << " l[#{@marbels[:l]}]"
    ret << "*" if @active_player == :l
    ret << "\n" << @board[:l][0, 8].inspect
    ret << "\n" << @board[:r][0, 8].reverse!.inspect  << " r[#{@marbels[:r]}]"
    ret << "*" if @active_player == :r
    ret << "\n" << @board[:r][8, 15].inspect
  end
  private
    def other_player
      (@players - [@active_player]).first
    end
end

class BaoBot < Bao
  def initialize(depth=1)
    @depth = [depth, 0].max
    super()
    @computer_player = other_player()
    @prng = Random.new
  end

  def move(num)
    super(num)

    fittness = []
    threads = []
    @board_size.times do |i|
      threads << Thread.new do
        begin
          @depth.times do |j|
            fittness[i] += trymove(i)
          end
        rescue GameOver, InvalidMove
          fittness[i] = 0
        end
      end
    end

    if @prng.rand(2) == 0
      move(fittness.index(fittness.max))
    else
      move(fittness.rindex(fittness.max))
    end

    self
  end
  alias_method :m, :move

  private
    def trymove(num)
      savestate
      super.move(num)
      returnstate

      return @eaten_marbels
    end

    def savestate
      @state = [@board, @marbels, @active_player, @taken_marbels]
    end
    def returnstate
      @board, @marbels, @active_player, @taken_marbels = @state
    end
end


# tests
b = Bao.new
raise ImplementationError unless b.inspect == "\n[0, 0, 0, 0, 0, 0, 0, 0] l[22]*\n[0, 2, 2, 6, 0, 0, 0, 0]\n[0, 0, 0, 0, 6, 2, 2, 0] r[22]\n[0, 0, 0, 0, 0, 0, 0, 0]"
b.move(3)
raise ImplementationError unless b.inspect == "\n[0, 0, 0, 0, 0, 1, 1, 1] l[21]\n[0, 2, 2, 0, 1, 1, 1, 1]\n[0, 0, 0, 0, 6, 2, 2, 0] r[22]*\n[0, 0, 0, 0, 0, 0, 0, 0]"
b.move(3)
raise ImplementationError unless b.inspect == "\n[0, 0, 0, 0, 0, 1, 1, 1] l[21]*\n[0, 2, 2, 0, 1, 1, 1, 1]\n[1, 1, 1, 1, 0, 2, 2, 0] r[21]\n[1, 1, 1, 0, 0, 0, 0, 0]"
b.move(4)
raise ImplementationError unless b.inspect == "\n[0, 0, 0, 1, 1, 0, 2, 2] l[20]\n[0, 2, 2, 0, 0, 2, 0, 2]\n[1, 1, 1, 1, 0, 2, 0, 0] r[21]*\n[1, 1, 1, 0, 0, 0, 0, 0]"
b.move(4)
raise ImplementationError unless b.inspect == "\n[0, 0, 0, 1, 1, 0, 2, 2] l[20]*\n[0, 2, 2, 0, 0, 2, 0, 2]\n[2, 0, 2, 0, 0, 2, 0, 0] r[20]\n[0, 2, 0, 1, 1, 0, 0, 0]"
b.move(2)
raise ImplementationError unless b.inspect == "\n[0, 0, 0, 1, 1, 1, 3, 3] l[19]\n[0, 2, 0, 1, 1, 0, 1, 3]\n[2, 0, 2, 0, 0, 0, 0, 0] r[20]*\n[0, 2, 0, 1, 1, 0, 0, 0]"
b = nil
