require_relative '../lib/gamelib'

class LineBreaking < TerminalGame
  def initialize(size_x=120, size_y=33, text=nil)
    @fps = :manual

    @scroll_pos = [0,0]
    @size = [size_y, size_x]
    @hyphenation = true
    @annotations = true
    @hyphenate_harder = false

    @text = text || (
      # 'Sixty-Four comes asking for bread. She folded her handkerchief neatly. The underground bunker was filled with chips and candy. The bees decided to have a mutiny against their queen. There were three sphered rocks congregating in a cubed room. Best friends are like old tomatoes and shoelaces. Baby wipes are made of chocolate stardust. The rain pelted the windshield as the darkness engulfed us.' +
      # "\n\n" +
      # 'The quick brown fox jumped over the lazy dog. ' +
      # # 'How vexingly quick daft zebras jump!  ' + # double space is on purpose to see if its preserved
      # # 'Amazingly few disotheques provide jukeboxes. ' +
      # 'My girl wove six dozen plaid jackets before she quit. ' +
      # 'A wizard\'s job is to vex chumps quickly in fog. ' +
      # 'Sixty zippers were quickly picket from a woven jute bag. ' +
      # "\n\n" +
      # 'HAMBURGEFONTSIV ZWYKTY Högertrafikomläggningen waverly hawaiian havana plywood vanwayman difficult waffles' +
      # "\n\n" +
      'But I must explain to you how all this mistaken idea of denouncing pleasure and praising pain was born and I will give you a complete account of the system, and expound the actual teachings of the great explorer of the truth, the master builder of human happiness. No one rejects, dislikes, or avoids pleasure itself, because it is pleasure, but because those who do not know how to pursue pleasure rationally encounter consequences that are extremely painful. Nor again is there anyone who loves or pursues or desires to obtain pain of itself, because it is pain, but because occasionally circumstances occur in which toil and pain can procure him some great pleasure. To take a trivial example, which of us ever undertakes laborious physical exercise, except to obtain some advantage from it? But who has any right to find fault with a man who chooses to enjoy a pleasure that has no annoying consequences, or one who avoids a pain that produces no resultant pleasure? On the other hand, we denounce with righteous indignation and dislike men who are so beguiled and demoralized by the charms of pleasure of the moment, so blinded by desire, that they cannot foresee the pain and trouble that are bound to ensue; and equal blame belongs to those who fail in their duty through weakness of will, which is the same as saying through shrinking from toil and pain. These cases are perfectly simple and easy to distinguish. In a free hour, when our power of choice is untrammelled and when nothing prevents our being able to do what we like best, every pleasure is to be welcomed and every pain avoided. But in certain circumstances and owing to the claims of duty or the obligations of business it will frequently occur that pleasures have to be repudiated and annoyances accepted. The wise man therefore always holds in these matters to this principle of selection: he rejects pleasures to secure other greater pleasures, or else he endures pains to avoid worse pains.'
       # + ' Citation end.'
    )
  end

  def draw
    clear
    move_cursor
    lengths = []
    text = break_lines(@text, @size[1], hyphenation: @hyphenation, hyphenate_harder: @hyphenate_harder)
    hyphen_score = text.hyphens.count{|e| e[:result].first.chomp!('-'); e[:result].map(&:length).min <= 3 }
    print text.split("\r\n").map{|s| lengths << s.length; @annotations ? "#{s.inspect} (#{s.length})" : s }[@scroll_pos[0]..(@scroll_pos[0] + @size[0])].join("\r\n")
    print "\r\n\r\n"
    puts "Wanted Size: #{@size[1]}, #{@hyphenation ? 'hyphenated' + (@hyphenate_harder ? ' hard': '') : ''}\r"
    puts "#{color(9)}badness score: #{text.badness}#{color_reset_code}\r"
    # puts "whitespace score: #{lengths.map{|l| r = (@size[1] - l); r <= 2 ? 0 : l == 0 ? 0 : r}.sum}\r"
    puts "hyphen count: #{text.hyphens.count}, hyphen score: #{hyphen_score}\r"
    puts "#{text.hyphens.map{|h| h.inspect }.join("\r\n")}"
  end

  def input_handler(input)
    case input
    when "\e[A" # up
      @scroll_pos[0] -= 1
      @scroll_pos[0] = 0 if @scroll_pos[0].negative?
    when "\e[B" # down
      @scroll_pos[0] += 1
    when "\e[1;5A" # ctrl+up
      @size[0] -= 1
      @size[0] = 0 if @size[0].negative?
    when "\e[1;5B" # ctrl+down
      @size[0] += 1
    when "\e[C" # right
      @size[1] += 1
    when "\e[D" # left
      @size[1] -= 1
    when "n"
      @annotations = ! @annotations
    when "h"
      @hyphenation = ! @hyphenation
    when "H"
      @hyphenate_harder = ! @hyphenate_harder
    # else
    #   raise TerminalGameEnd, input.inspect
    end
    draw
  end
end

if __FILE__ == $PROGRAM_NAME
  LineBreaking.new().run()
end
