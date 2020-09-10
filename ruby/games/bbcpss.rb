require 'eventmachine'

bbcpss.rb

#             schere  stein   papier  baby öl baby    condom  brunnen
# schere      -       -       -       -       -       -       -
# stein       stein   -       -       -       -       -       -
# papier      schere  papier  -       -       -       -       -
# baby öl     baby öl stein   baby öl -       -       -       -
# baby        schere  stein   baby    baby    -       -       -
# condom      schere  condom  papier  baby öl condom  -       -
# brunnen     brunnen brunnen papier  brunnen baby    condom  -


WINS_AGAINST = {
  schere:  %w[papier baby    condom ],
  stein:   %w[schere baby_öl baby   ],
  papier:  %w[stein  condom  brunnen],
  baby_öl: %w[schere papier  condom ],
  baby:    %w[papier baby_öl brunnen],
  brunnen: %w[schere stein   baby_öl],
  condom:  %w[stein  baby    brunnen],
}



choosen = readline.strip
computer = WINS_AGAINST.keys.sample
if WINS_AGAINST[computer].include?(choosen)
end
