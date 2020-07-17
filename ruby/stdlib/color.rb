class Color
  include Comparable
  attr :rgb
  def <=>(other)
    rgb <=> other.rgb
  end

  def initialize(r,g,b)
    @rgb = [r,g,b]
  end

  alias eql? ==
  def hash
    rgb.hash
  end

  def inspect
    "#<Color:#{to_hex}>"
  end

  def self.from_hex(str)
    hex = str.delete_prefix("#")
    raise "wrong length" if hex.length != 6
    Color.new(*hex.split('').each_slice(2).map{|e| Integer(e.join(''), 16) })
  end
  def to_hex
    '#' + rgb.map{|e| (e+256).to_s(16)[1..2] }.join('')
  end

  def offset(other)
    rgb.zip(other.rgb).map{|a,b|a-b}
  end

  COLOR_NAMES = Hash[DATA.read.each_line.drop(1).map{|e| c,n = e.split(' ', 2); [Color.from_hex(c), n.strip]}]
  def to_name(inexact = true)
    return COLOR_NAMES[self] if COLOR_NAMES[self] || !inexact
    COLOR_NAMES.min_by{|(k,_)| offset(k).map(&:abs).sum }.last
  end
  def self.from_name(str)
    COLOR_NAMES.key(str)
  end
end

raise 'AH' unless Color.from_hex("#00fbb1").to_name == "greenish turquoise"
raise 'AH' unless Color.from_hex("#00fbb1").to_name(false).nil?
raise 'AH' unless Color.from_hex("#00fbb0").to_name(false) == "greenish turquoise"
raise 'AH' unless Color.from_hex("#00fbb0").eql?(Color.from_hex("#00fbb0"))
raise "AH" unless Color.from_hex("#00fbb0") == Color.new(0, 0xfb, 0xb0)
raise "AH" unless Color.from_hex("#00fbb0") <= Color.new(1, 0xfb, 0xb0)
raise "AH" unless Color.from_hex("#00fbb0") >= Color.new(0, 0xfa, 0xb0)
raise 'AH' unless Color.from_hex("#00fbb0") == Color.from_name("greenish turquoise")

__END__
# License: http://creativecommons.org/publicdomain/zero/1.0/
#000000 black
#000133 very dark blue
#00022e dark navy blue
#00035b dark blue
#000435 dark navy
#001146 navy blue
#002d04 dark forest green
#004577 prussian blue
#005249 dark blue green
#00555a deep teal
#005f6a petrol
#009337 kelley green
#00fbb0 greenish turquoise
#00ffff cyan
#010fcc true blue
#01153e navy
#01386a marine blue
#014182 darkish blue
#014600 racing green
#014d4e dark teal
#015482 deep sea blue
#0165fc bright blue
#016795 peacock blue
#017371 dark aquamarine
#017374 deep turquoise
#017a79 bluegreen
#017b92 ocean
#01889f teal blue
#019529 irish green
#01a049 emerald
#01b44c shamrock
#01c08d green/blue
#01f9c6 bright teal
#01ff07 bright green
#020035 midnight blue
#0203e2 pure blue
#02066f dark royal blue
#021bf9 rich blue
#02590f deep green
#028f1e emerald green
#029386 teal
#02ab2e kelly green
#02c14d shamrock green
#02ccfe bright sky blue
#02d8e9 aqua blue
#03012d midnight
#030764 darkblue
#030aa7 cobalt blue
#033500 dark green
#0339f8 vibrant blue
#0343df blue
#03719c ocean blue
#040273 deep blue
#040348 night blue
#042e60 marine
#044a05 bottle green
#045c5a dark turquoise
#047495 sea blue
#048243 jungle green
#0485d1 cerulean
#04d8b2 aquamarine
#04d9ff neon blue
#04f489 turquoise green
#0504aa royal blue
#05472a evergreen
#05480d british racing green
#054907 darkgreen
#05696b dark aqua
#056eee cerulean blue
#05ffa6 bright sea green
#062e03 very dark green
#06470c forest green
#0652ff electric blue
#069af3 azure
#06b1c4 turquoise blue
#06b48b green blue
#06c2ac turquoise
#070d0d almost black
#0804f9 primary blue
#08787f deep aqua
#089404 true green
#08ff08 fluorescent green
#0a437a twilight blue
#0a481e pine green
#0a5f38 spruce
#0a888a dark cyan
#0add08 vibrant green
#0aff02 fluro green
#0b4008 hunter green
#0b5509 forest
#0b8b87 greenish blue
#0bf77d minty green
#0bf9ea bright aqua
#0c06f7 strong blue
#0c1793 royal
#0cb577 green teal
#0cdc73 tealish green
#0cff0c neon green
#0d75f8 deep sky blue
#0e87cc water blue
#0f9b8e blue/green
#0ffef9 bright turquoise
#107ab0 nice blue
#10a674 bluish green
#11875d dark sea green
#12e193 aqua green
#137e6d blue green
#13bbaf topaz
#13eac9 aqua
#152eff vivid blue
#154406 forrest green
#155084 light navy
#15b01a green
#1805db ultramarine blue
#18d17b seaweed
#1b2431 dark
#1bfc06 highlighter green
#1d0200 very dark brown
#1d5dec azul
#1e488f cobalt
#1e9167 viridian
#1ef876 spearmint
#1f0954 dark indigo
#1f3b4d dark blue grey
#1f6357 dark green blue
#1fa774 jade
#1fb57a dark seafoam
#2000b1 ultramarine
#20c073 dark mint green
#20f986 wintergreen
#2138ab sapphire
#214761 dark slate blue
#21c36f algae green
#21fc0d electric green
#2242c7 blue blue
#23c48b greenblue
#247afd clear blue
#24bca8 tealish
#25a36f teal green
#25ff29 hot green
#26538d dusk blue
#26f7fd bright light blue
#276ab3 mid blue
#280137 midnight purple
#287c37 darkish green
#29465b dark grey blue
#2976bb bluish
#2a0134 very dark purple
#2a7e19 tree green
#2afeb7 greenish cyan
#2b5d34 pine
#2baf6a jade green
#2bb179 bluey green
#2c6fbb medium blue
#2cfa1f radioactive green
#2dfe54 bright light green
#2e5a88 light navy blue
#2ee8bb aqua marine
#2fef10 vivid green
#31668a ugly blue
#32bf84 greenish teal
#33b864 cool green
#34013f dark violet
#341c02 dark brown
#343837 charcoal
#35063e dark purple
#35530a navy green
#35ad6b seaweed green
#36013f deep purple
#363737 dark grey
#373e02 dark olive
#3778bf windows blue
#380282 indigo
#380835 eggplant
#388004 dark grass green
#39ad48 medium green
#3a18b1 indigo blue
#3a2efe light royal blue
#3ae57f weird green
#3b5b92 denim blue
#3b638c denim
#3b719f muted blue
#3c0008 dark maroon
#3c4142 charcoal grey
#3c4d03 dark olive green
#3c73a8 flat blue
#3c9992 sea
#3d0734 aubergine
#3d1c02 chocolate
#3d7afd lightish blue
#3d9973 ocean green
#3e82fc dodger blue
#3eaf76 dark seafoam green
#3f012c dark plum
#3f829d dirty blue
#3f9b0b grass green
#40a368 greenish
#40fd14 poison green
#410200 deep brown
#411900 chocolate brown
#419c03 grassy green
#41fdfe bright cyan
#42b395 greeny blue
#430541 eggplant purple
#436bad french blue
#448ee4 dark sky blue
#464196 blueberry
#475f94 dusky blue
#48c072 dark mint
#490648 deep violet
#49759c dull blue
#4984b8 cool blue
#4a0100 mahogany
#4b006e royal purple
#4b0101 dried blood
#4b57db warm blue
#4b5d16 army green
#4b6113 camouflage green
#4c9085 dusty teal
#4da409 lawn green
#4e0550 plum purple
#4e518b twilight
#4e5481 dusk
#4e7496 cadet blue
#4efd54 light neon green
#4f738e metallic blue
#4f9153 light forest green
#507b9c stormy blue
#50a747 mid green
#510ac9 violet blue
#516572 slate
#5170d7 cornflower blue
#51b73b leafy green
#526525 camo green
#533cc6 blue with a hint of purple
#536267 gunmetal
#53fca1 sea green
#53fe5c light bright green
#544e03 green brown
#548d44 fern green
#54ac68 algae
#5539cc blurple
#5684ae off blue
#56ae57 dark pastel green
#56fca2 light green blue
#5729ce blue purple
#580f41 plum
#58bc08 frog green
#59656d slate grey
#598556 dark sage
#5a06ef blue/purple
#5a7d9a steel blue
#5a86ad dusty blue
#5b7c99 slate blue
#5c8b15 sap green
#5ca904 leaf green
#5cac2d grass
#5cb200 kermit green
#5d06e9 blue violet
#5d1451 grape purple
#5d21d0 purple/blue
#5e819d greyish blue
#5e9b8a grey teal
#5edc1f green apple
#5f34e7 purpley blue
#5f9e8f dull teal
#5fa052 muted green
#601ef9 purplish blue
#60460f mud brown
#606602 mud green
#607c8e blue grey
#610023 burgundy
#6140ef purpleish blue
#61de2a toxic green
#61e160 lightish green
#6241c7 bluey purple
#6258c4 iris
#632de9 purple blue
#638b27 mossy green
#63a950 fern
#63b365 boring green
#63f7b4 light greenish blue
#645403 olive brown
#647d8e grey/blue
#6488ea soft blue
#650021 maroon
#653700 brown
#657432 muddy green
#658b38 moss green
#658cbb faded blue
#658d6d slate green
#65ab7c tea
#65fe08 bright lime green
#661aee purply blue
#665fd1 dark periwinkle
#667c3e military green
#667e2c dirty green
#673a3f purple brown
#677a04 olive green
#680018 claret
#6832e3 burple
#696006 greeny brown
#696112 greenish brown
#698339 swamp
#699d4c flat green
#69d84f fresh green
#6a6e09 brownish green
#6a79f7 cornflower
#6b4247 purplish brown
#6b7c85 battleship grey
#6b8ba4 grey blue
#6ba353 off green
#6c3461 grape
#6c7a0e murky green
#6d5acf light indigo
#6dedfd robin's egg
#6e1005 reddy brown
#6e750e olive
#6ecb3c apple
#6f6c0a browny green
#6f7632 olive drab
#6f7c00 poop green
#6f828a steel grey
#6fc276 soft green
#703be7 bluish purple
#706c11 brown green
#70b23f nasty green
#719f91 greyish teal
#71aa34 leaf
#720058 rich purple
#728639 khaki green
#728f02 dark yellow green
#730039 merlot
#734a65 dirty purple
#735c12 mud
#738595 steel
#742802 chestnut
#748500 swamp green
#748b97 bluish grey
#749551 drab green
#74a662 dull green
#750851 velvet
#751973 darkish purple
#758000 shit green
#758da3 blue/grey
#75b84f turtle green
#75bbfd sky blue
#75fd63 lighter green
#76424e brownish purple
#769958 moss
#76a973 dusty green
#76cd26 apple green
#76fda8 light bluish green
#76ff7b lightgreen
#770001 blood
#77926f green grey
#77a1b5 greyblue
#77ab56 asparagus
#789b73 grey green
#78d1b6 seafoam blue
#7a5901 poop brown
#7a687f purplish grey
#7a6a4f greyish brown
#7a9703 ugly green
#7af9ab seafoam green
#7b002c bordeaux
#7b0323 wine red
#7b5804 shit brown
#7bb274 faded green
#7bc8f6 lightblue
#7bf2da tiffany blue
#7bfdc7 light aquamarine
#7d7103 ugly brown
#7d7f7c medium grey
#7e1e9c purple
#7e4071 bruise
#7ea07a greeny grey
#7ebd01 dark lime green
#7ef4cc light turquoise
#7efbb3 light blue green
#7f2b0a reddish brown
#7f4e1e milk chocolate
#7f5112 medium brown
#7f5e00 poop
#7f5f00 shit
#7f684e dark taupe
#7f7053 grey brown
#7f8f4e camo
#80013f wine
#805b87 muted purple
#80f9ad seafoam
#820747 red purple
#825f87 dusty purple
#826d8c grey purple
#828344 drab
#82a67d greyish green
#82cafc sky
#82cbb2 pale teal
#836539 dirt brown
#840000 dark red
#84597e dull purple
#84b701 dark lime
#850e04 indian red
#856798 dark lavender
#85a3b2 bluegrey
#866f85 purple grey
#86775f brownish grey
#86a17d grey/green
#874c62 dark mauve
#8756e4 purpley
#875f42 cocoa
#876e4b dull brown
#87a922 avocado green
#87ae73 sage
#87fd05 bright lime
#885f01 poo brown
#886806 muddy brown
#887191 greyish purple
#889717 baby shit green
#88b378 sage green
#894585 light eggplant
#895b7b dusky purple
#89a0b0 bluey grey
#89a203 vomit green
#89fe05 lime green
#8a6e45 dirt
#8ab8fe carolina blue
#8af1fe robin egg blue
#8b2e16 red brown
#8b3103 rust brown
#8b88f8 lavender blue
#8c000f crimson
#8c0034 red wine
#8cfd7e easter green
#8cff9e baby green
#8cffdb light aqua
#8d5eb7 deep lavender
#8d8468 brown grey
#8e7618 hazel
#8e82fe periwinkle
#8eab12 pea green
#8ee53f kiwi green
#8f1402 brick red
#8f7303 poo
#8f8ce7 perrywinkle
#8f9805 baby poop green
#8f99fb periwinkle blue
#8fae22 icky green
#8fb67b lichen
#8ffe09 acid green
#8fff9f mint green
#90b134 avocado
#90e4c1 light teal
#90fda9 foam green
#910951 reddish purple
#916e99 faded purple
#920a4e mulberry
#922b05 brown red
#929591 grey
#929901 pea soup
#937c00 baby poop
#94568c purplish
#947706 puke brown
#947e94 purpley grey
#94a617 pea soup green
#94ac02 barf green
#94b21c sickly green
#952e8f warm purple
#95a3a6 cool grey
#95d0fc light blue
#960056 dark magenta
#964e02 warm brown
#966ebd deep lilac
#96ae8d greenish grey
#96b403 booger green
#96f97b light green
#978a84 warm grey
#980002 blood red
#983fb2 purply
#98568d purpleish
#985e2b sepia
#98eff9 robin's egg blue
#98f6b0 light sea green
#9900fa vivid purple
#990147 purple red
#990f4b berry
#997570 reddish grey
#99cc04 slime green
#9a0200 deep red
#9a0eea violet
#9a3001 auburn
#9a6200 raw sienna
#9aae07 puke green
#9af764 light grass green
#9b5fc0 amethyst
#9b7a01 yellowish brown
#9b8f55 dark khaki
#9bb53c booger
#9be5aa hospital green
#9c6d57 brownish
#9c6da5 dark lilac
#9cbb04 bright olive
#9cef43 kiwi
#9d0216 carmine
#9d0759 dark fuchsia
#9d5783 light plum
#9d7651 mocha
#9db92c sick green
#9dbcd4 light grey blue
#9dc100 snot green
#9dff00 bright yellow green
#9e003a cranberry
#9e0168 red violet
#9e3623 brownish red
#9e43a2 medium purple
#9f2305 burnt red
#9f8303 diarrhea
#9ffeb0 mint
#a0025c deep magenta
#a00498 barney purple
#a03623 brick
#a0450e burnt umber
#a0bf16 gross green
#a0febf light seafoam
#a13905 russet
#a24857 light maroon
#a2653e earth
#a2a415 vomit
#a2bffe pastel blue
#a2cffe baby blue
#a442a0 ugly purple
#a484ac heather
#a4be5c light olive green
#a4bf20 pea
#a50055 violet red
#a552e6 lightish purple
#a55af4 lighter purple
#a57e52 puce
#a5a391 cement
#a5a502 puke
#a5fbd5 pale turquoise
#a66fb5 soft purple
#a6814c coffee
#a6c875 light moss green
#a6fbb2 light mint green
#a75e09 raw umber
#a7ffb5 light seafoam green
#a83c09 rust
#a8415b light burgundy
#a87900 bronze
#a87dc2 wisteria
#a88905 dark mustard
#a88f59 dark sand
#a8a495 greyish
#a8b504 mustard green
#a8ff04 electric lime
#a90308 darkish red
#a9561e sienna
#a9be70 tan green
#a9f971 spring green
#aa23ff electric purple
#aa2704 rust red
#aaa662 khaki
#aaff32 lime
#ab1239 rouge
#ab7e4c tan brown
#ab9004 baby poo
#ac1db8 barney
#ac4f06 cinnamon
#ac7434 leather
#ac7e04 mustard brown
#ac86a8 dusty lavender
#ac9362 dark beige
#acbb0d snot
#acbf69 light olive
#acc2d9 cloudy blue
#acfffc light cyan
#ad03de vibrant purple
#ad0afd bright violet
#ad8150 light brown
#ad900d baby shit brown
#ada587 stone
#adf802 lemon green
#ae7181 mauve
#ae8b0c yellowy brown
#aefd6c light lime
#aeff6e key lime
#af2f0d rusty red
#af6f09 caramel
#af884a dark tan
#afa88b bland
#b00149 raspberry
#b0054b purplish red
#b04e0f burnt sienna
#b0dd16 yellowish green
#b0ff9d pastel green
#b16002 orangey brown
#b17261 pinkish brown
#b1916e pale brown
#b1d1fc powder blue
#b1d27b pale olive green
#b1fc99 pale light green
#b1ff65 pale lime green
#b25f03 orangish brown
#b26400 umber
#b2713d clay brown
#b27a01 golden brown
#b29705 brown yellow
#b2996e dust
#b2fba5 light pastel green
#b36ff6 light urple
#b5485d dark rose
#b59410 dark gold
#b5c306 bile
#b5ce08 green/yellow
#b66325 copper
#b66a50 clay
#b6c406 baby puke green
#b6ffbb light mint
#b75203 burnt siena
#b790d4 pale purple
#b79400 yellow brown
#b7c9e2 light blue grey
#b7e1a1 light grey green
#b7fffa pale cyan
#b8ffeb pale aqua
#b9484e dusty red
#b96902 brown orange
#b9a281 taupe
#b9cc81 pale olive
#b9ff66 light lime green
#ba6873 dusky rose
#ba9e88 mushroom
#bb3f3f dull red
#bbf90f yellowgreen
#bc13fe neon purple
#bccb7a greenish tan
#bcecac light sage
#bcf5a6 washed out green
#bd6c48 adobe
#bdf6fe pale sky blue
#bdf8a3 tea green
#be0119 scarlet
#be013c rose red
#be03fd bright purple
#be6400 orange brown
#beae8a putty
#befd73 pale lime
#befdb7 celadon
#bf77f6 light purple
#bf9005 ochre
#bf9b0c ocher
#bfac05 muddy yellow
#bff128 yellowy green
#bffe28 lemon lime
#c0022f lipstick red
#c04e01 burnt orange
#c071fe easter purple
#c0737a dusty rose
#c0fa8b pistachio
#c0fb2d yellow green
#c14a09 brick orange
#c1c6fc light periwinkle
#c1f80a chartreuse
#c1fd95 celery
#c20078 magenta
#c27e79 brownish pink
#c292a1 light mauve
#c2b709 olive yellow
#c2be0e puke yellow
#c2ff89 light yellowish green
#c3909b grey pink
#c3fbf4 duck egg blue
#c44240 reddish
#c45508 rust orange
#c48efd liliac
#c4a661 sandy brown
#c4fe82 light pea green
#c4fff7 eggshell blue
#c5c9c7 silver
#c65102 dark orange
#c69c04 ocre
#c69f59 camel
#c6f808 greeny yellow
#c6fcff light sky blue
#c74767 deep rose
#c760ff bright lavender
#c77986 old pink
#c79fef lavender
#c7ac7d toupe
#c7c10c vomit yellow
#c7fdb5 pale green
#c83cb9 purpley pink
#c85a53 dark salmon
#c875c4 orchid
#c87606 dirty orange
#c87f89 old rose
#c88d94 greyish pink
#c8aca9 pinkish grey
#c8fd3d yellow/green
#c8ffb0 light light green
#c94cbe pinky purple
#c95efb bright lilac
#c9643b terra cotta
#c9ae74 sandstone
#c9b003 brownish yellow
#c9d179 greenish beige
#c9ff27 green yellow
#ca0147 ruby
#ca6641 terracotta
#ca6b02 browny orange
#ca7b80 dirty pink
#ca9bf7 baby purple
#caa0ff pastel purple
#cafffb light light blue
#cb00f5 hot purple
#cb0162 deep pink
#cb416b dark pink
#cb6843 terracota
#cb7723 brownish orange
#cb9d06 yellow ochre
#cba560 sand brown
#cbf85f pear
#cc7a8b dusky pink
#ccad60 desert
#ccfd7f light yellow green
#cd5909 rusty orange
#cd7584 ugly pink
#cdc50a dirty yellow
#cdfd02 greenish yellow
#ce5dae purplish pink
#cea2fd lilac
#ceaefa pale violet
#ceb301 mustard
#cf0234 cherry
#cf524e dark coral
#cf6275 rose
#cfaf7b fawn
#cffdbc very pale green
#cfff04 neon yellow
#d0c101 ugly yellow
#d0e429 sickly yellow
#d0fe1d lime yellow
#d0fefe pale blue
#d1768f muted pink
#d1b26f tan
#d1ffbd very light green
#d2bd0a mustard yellow
#d3494e faded red
#d3b683 very light brown
#d46a7e pinkish
#d4ffff really light blue
#d5174e lipstick
#d5869d dull pink
#d58a94 dusty pink
#d5ab09 burnt yellow
#d5b60a dark yellow
#d5ffff very light blue
#d648d7 pinkish purple
#d6b4fc light violet
#d6fffa ice
#d6fffe very pale blue
#d725de purple/pink
#d767ad pale magenta
#d7fffe ice blue
#d8863b dull orange
#d8dcd6 light grey
#d90166 dark hot pink
#d94ff5 heliotrope
#d9544d pale red
#d99b82 pinkish tan
#da467d darkish pink
#db4bda pink purple
#db5856 pastel red
#dbb40c gold
#dc4d01 deep orange
#dd85d7 lavender pink
#ddd618 piss yellow
#de0c62 cerise
#de7e5d dark peach
#de9dac faded pink
#df4ec8 purpleish pink
#dfc5fe light lavender
#e03fd8 purple pink
#e17701 pumpkin
#e2ca76 sand
#e4cbff pale lilac
#e50000 red
#e6daa6 beige
#e6f2a2 light khaki
#e78ea5 pig pink
#ec2d01 tomato red
#ed0dd9 fuchsia
#edc8ff light lilac
#eecffe pale lavender
#eedc5b dull yellow
#ef1de7 pink/purple
#ef4026 tomato
#efb435 macaroni and cheese
#efc0fe light lavendar
#f075e6 purply pink
#f0833a dusty orange
#f0944d faded orange
#f10c45 pinkish red
#f1da7a sandy
#f1f33f off yellow
#f29e8e blush
#f2ab15 squash
#f36196 medium pink
#f4320c vermillion
#f43605 orangish red
#f4d054 maize
#f504c9 hot magenta
#f5054f pink red
#f5bf03 golden
#f6688e rosy pink
#f6cefc very light purple
#f7022a cherry red
#f7879a rose pink
#f7d560 light mustard
#f8481c reddish orange
#f97306 orange
#f9bc08 golden rod
#fa2a55 red pink
#fa4224 orangey red
#fa5ff7 light magenta
#fac205 goldenrod
#faee66 yellowish
#fafe4b banana yellow
#fb2943 strawberry
#fb5581 warm pink
#fb5ffc violet pink
#fb7d07 pumpkin orange
#fbdd7e wheat
#fbeeac light tan
#fc2647 pinky red
#fc5a50 coral
#fc824a orangish
#fc86aa pinky
#fcb001 yellow orange
#fcc006 marigold
#fce166 sand yellow
#fcf679 straw
#fcfc81 yellowish tan
#fd3c06 red orange
#fd411e orange red
#fd4659 watermelon
#fd5956 grapefruit
#fd798f carnation
#fd8d49 orangeish
#fdaa48 light orange
#fdb0c0 soft pink
#fdb147 butterscotch
#fdb915 orangey yellow
#fdc1c5 pale rose
#fddc5c light gold
#fdde6c pale gold
#fdee73 sandy yellow
#fdfdfe pale grey
#fdff38 lemon yellow
#fdff52 lemon
#fdff63 canary
#fe0002 fire engine red
#fe019a neon pink
#fe01b1 bright pink
#fe02a2 shocking pink
#fe2c54 reddish pink
#fe2f4a lightish red
#fe420f orangered
#fe46a5 barbie pink
#fe4b03 blood orange
#fe7b7c salmon pink
#fe828c blush pink
#fe83cc bubblegum pink
#fe86a4 rosa
#fea993 light salmon
#feb209 saffron
#feb308 amber
#fec615 golden yellow
#fed0fc pale mauve
#fedf08 dandelion
#fef69e buff
#fefcaf parchment
#feff7f faded yellow
#feffca ecru
#ff000d bright red
#ff028d hot pink
#ff0490 electric pink
#ff073a neon red
#ff0789 strong pink
#ff08e8 bright magenta
#ff474c light red
#ff5b00 bright orange
#ff6163 coral pink
#ff63e9 candy pink
#ff69af bubble gum pink
#ff6cb5 bubblegum
#ff6f52 orange pink
#ff724c pinkish orange
#ff7855 melon
#ff796c salmon
#ff7fa7 carnation pink
#ff81c0 pink
#ff9408 tangerine
#ff964f pastel orange
#ff9a8a peachy pink
#ffa62b mango
#ffa756 pale orange
#ffab0f yellowish orange
#ffad01 orange yellow
#ffb07c peach
#ffb16d apricot
#ffb19a pale salmon
#ffb2d0 powder pink
#ffb7ce baby pink
#ffbacd pastel pink
#ffc512 sunflower
#ffc5cb light rose
#ffcfdc pale pink
#ffd1df light pink
#ffd8b1 light peach
#ffda03 sunflower yellow
#ffdf22 sun yellow
#ffe36e yellow tan
#ffe5ad pale peach
#fff39a dark cream
#fff4f2 very light pink
#fff917 sunny yellow
#fff9d0 pale
#fffa86 manilla
#fffcc4 egg shell
#fffd01 bright yellow
#fffd37 sunshine yellow
#fffd74 butter yellow
#fffd78 custard
#fffe40 canary yellow
#fffe71 pastel yellow
#fffe7a light yellow
#fffeb6 light beige
#ffff14 yellow
#ffff7e banana
#ffff81 butter
#ffff84 pale yellow
#ffffb6 creme
#ffffc2 cream
#ffffcb ivory
#ffffd4 eggshell
#ffffe4 off white
#ffffff white
