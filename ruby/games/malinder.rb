require 'fileutils'
require 'json'
require 'net/http'
def require_optional(name)
	require name
	true
rescue LoadError
	yield if block_given?
	false
end
VIPS = require_optional('vips')
require_optional(File.dirname(__FILE__) + '/../stdlib/duration'){
	class Duration
		def initialize(secs)
			@secs = secs
			@secs
		end
		def to_s
			@secs.to_s
		end
	end
}
require_optional(File.dirname(__FILE__) + '/lib/gamelib'){
	class TerminalGame
		def run
			raise "missing ./lib/gamelib"
		end
	end
}

# config file: malinder_config.rb in same folder as this
# things you may put in your config, like:
# DEFAULT_HEADERS = {'X-MAL-CLIENT-ID': 'asdf'}
# LOG_SUFFIX = '-yourname'
CACHE_DIR = ENV.fetch('XDG_CACHE_HOME', ENV.fetch('HOME') + '/.cache') + '/malinder/'
require_optional(CACHE_DIR + '/config.rb')

def configurable_default(name, default)
	Object.const_set(name, default) unless Object.const_defined?(name)
end
# configurable_default
configurable_default(:API, 'https://api.myanimelist.net/v2/')
FileUtils.mkdir_p(CACHE_DIR + 'images/')
configurable_default(:LOG_SUFFIX, '')
configurable_default(:LOG_FILE_PATH, "#{CACHE_DIR}choices#{LOG_SUFFIX}.log")
configurable_default(:BAD_WORDS,
	%w(
		mini idol cultivat mini chibi promotion game pokemon sport mecha machine limited trailer short season
		special extra harem hentai ecchi kids collaboration commercial precure reborn rebirth revive isekai
		reincar sanrio compilation
		youku bilibili
	)	+ ['love live', 'boys love', 'sailor moon', 'music film', 'music video']
)
configurable_default(:BAD_WORDS_REGEX, /\b#{ Regexp.union(BAD_WORDS).source }\b/i)

# not configurable
CACHE = {}
CACHE_BY_RANK = {}
IMAGE_CACHE = {}
LOG_FILE = File.open(LOG_FILE_PATH, 'a+')
LOG_FILE.sync = true
CHOICES = Hash[LOG_FILE.each_line.map{|l| id, c, ts = l.split("\t"); [id, {choice:c, ts: ts}]}]
MAL_PREFIX = 'https://myanimelist.net/anime/'


def load_all_to_cache()
	Dir[CACHE_DIR + 'sources/*'].each do |s|
		JSON.parse(File.read(s))['data'].each do |v|
			CACHE[v['node']['id']] ||= v['node']
			CACHE_BY_RANK[v['node']['rank']] ||= v['node']['id']
		end
	end
end
def cache_search(needle)
	load_all_to_cache() if CACHE.empty?
	search = /#{needle}/i
	CACHE.select do |_,v|
		[v['title'], *v['alternative_titles']&.values.flatten].any?{|s| s.match?(search)}
	end
end

def compare(a,b)
	[a,b].map do |csv|
		csv.group_by{|_,_,_,d| d.split(',').first}
	end
end

def fetch(url, **stuff)
	headers = stuff.fetch(:headers, {})
	content = stuff[:content]

	uri = URI.parse(url)
	ret = Net::HTTP.start(uri.hostname, uri.port, use_ssl: stuff.fetch(:use_ssl, uri.scheme == 'https')) do |http|
		verb = stuff[:verb] || content.nil? ? 'GET' : 'POST'
		http.send_request(verb, uri, content, headers)
	end
	raise ret.code if ret.code != '200'
	return ret
end
# fetch(API + 'anime/30230')
# fetch(j['main_picture']['large'])

def image(anime)
	id = anime['id']
	return IMAGE_CACHE[id] if IMAGE_CACHE.has_key?(id)
	path = CACHE_DIR + 'images/' + id.to_i.to_s + '.png'
	if File.exists?(path)
		begin
			IMAGE_CACHE[id] = Vips::Image.new_from_file(path)
			return IMAGE_CACHE[id]
		rescue
			nil
		end
	end
	if anime['main_picture']
		url = anime['main_picture'].fetch('large', anime['main_picture'].fetch('medium'))
		image = fetch(url).body
		File.write(path, image)
		IMAGE_CACHE[id] = Vips::Image.new_from_buffer(image, '')
	else
		IMAGE_CACHE[id] = Vips::Image.text("No Image\n:(")
	end
end

def season_shortcuts(input)
	s = MALinder::SEASON_SHORTCUTS.fetch(input, input)
	raise "'#{input.inspect}' is not a season" unless MALinder::SEASON_SHORTCUTS.values.include?(s)
	s
end


class MALinder < TerminalGame
	SEASON_SHORTCUTS = {
		'w'=> 'winter', 'sp'=> 'spring', 'su'=> 'summer', 'f'=> 'fall',
		'1'=> 'winter', '2'=> 'spring', '3'=> 'summer', '4'=> 'fall',
	}
	def inspect #reduce size of errors
		'#<MALinder>'
	end
	def initialize(year, season)
		@fps = :manual
		@require_kitty_graphics = true
#		@show_overflow = true

		season = season_shortcuts(season)
		year = Integer(year, 10) # raise if year is not an integer
		@which_season = [year, season]
		season_file = "#{CACHE_DIR}sources/#{year}-#{season}.json"
		raise 'missing json, run malinder.sh first' unless File.exists?(season_file)
		@season = JSON.parse(File.read(season_file))['data'].map{|v|v['node']}
		@season.reject!{|a| CHOICES.has_key?(a['id'].to_s)}
		@season.reject!{|a| a['media_type'] == 'music'}
		@season.select!{|a| a['start_season']['year'] == year}
#		@season.select!{|a| a['nsfw'] == 'white'}
		raise 'empty (all marked or nothing here)' if @season.empty?
		@current = 0
	end
	def size_change_handler;sync_draw{draw(true)};end #redraw on size change

	def draw(redraw=false)
		raise 'empty (all marked or nothing here)' if @season.empty?
		anime = @season[@current]
		if VIPS
			current_img = image(anime)
			scale_by = current_img.size.zip([@size_x/2, @size_y]).map{|want,have| want > have ? have/want.to_f : 1}.min
			buffer = (scale_by == 1 ? current_img : current_img.resize(scale_by)).pngsave_buffer
		end
		counter = " (#{@current+1}/#{@season.size})"
		normal_title = text_color_bad_words((anime['title'].inspect + counter).center(@cols))
		move_cursor(0,0)
		clear
		if anime['alternative_titles']
			if anime['alternative_titles']['en'] and anime['alternative_titles']['en'] != ''
				print(text_color_bad_words((anime['alternative_titles']['en'].inspect + counter).center(@cols)))
			else
				print(normal_title)
			end
			if anime['alternative_titles']['ja']
				print("\r\n")
				overlength = anime['alternative_titles']['ja'].gsub(/[0-9a-z\/+_-]/i, '').length
				print(text_color_bad_words((anime['alternative_titles']['ja']).center(@cols - overlength)))
			end
		else
			print(normal_title)
		end
		print("\r\n"*2)
		paragraph = anime['synopsis'] + "\n"
		paragraph += "\nType: #{anime['media_type']}" if anime['media_type']
		paragraph += "\nSource: #{anime['source']}" if anime['source']
		paragraph += "\nStart: #{anime['start_date']}" if anime['start_date']
		paragraph += "\nEpisodes: #{anime['num_episodes']}" if anime['num_episodes'] and anime['num_episodes'] != 0
		paragraph += "\nDuration: #{Duration.new(anime['average_episode_duration']).to_s}" if anime['average_episode_duration']
		paragraph += "\nGenres: #{anime['genres'].map{|x|x['name']}.join(', ')}" if anime['genres']
		paragraph += "\n\nLink: #{MAL_PREFIX}#{anime['id']}"
		paragraph = break_lines(text_color_bad_words(paragraph), @cols/2+1)
		print(paragraph.gsub(/\n(\s*\n)+/, "\n\n").gsub(/\n/, "\r\n"))
		move_cursor(0,0)
		if VIPS
			imgid = kitty_graphics_img_load(buffer)
			kitty_graphics_img_pixel_place_center(imgid, *current_img.size.map{|e| (e*scale_by).to_i}, (@size_x/4).to_i, 0)
		end
		# print("\r\n")
		# kitty_graphics_img_display(imgid)
	end

	def input_handler(input)
		case input
		when "\e[C" #right
			@current += 1
			@current %= @season.size
		when "\e[D" #left
			@current -= 1
			@current = @season.size-1 if @current < 0
		when "\e", 'q' #quit
			exit()
		when '1' #, 'q' # commented out because annoying
			logchoice('nope')
		when '2', 'a'
			logchoice('okay')
		when '3', 'y'
			logchoice('want')
		else
			return
		end
		draw
	end

	def logchoice(choice)
		anime = @season[@current]
		LOG_FILE.write("#{anime['id']}\t#{@which_season.join("\t")}\t#{choice}\t#{Time.now.to_i}\t#{anime['title']}\n")
		@season.delete_at(@current)
		exit() if @season.empty?
		@current %= @season.size
	end

	def text_color_bad_words(text)
		text.gsub(BAD_WORDS_REGEX){|w| get_color_code([255,0,0]) + w + color_reset_code()}
	end
end


if __FILE__ == $PROGRAM_NAME
	GC.disable
	if ARGV.first == 'results'
		ARGV.shift
		if ARGV.empty?
			puts 'give me two files to compare,'
			puts '  or one if you got your own.'
			exit
		end
		season = nil
		if ARGV.length >= 3
			season = {
				'season' => season_shortcuts(ARGV.pop),
				'year' => Integer(ARGV.pop, 10),
			}
		end
		p season

		require 'csv'
		csv_options = {
			skip_blanks: true,
			# skip_lines: /^#/,
			col_sep: "\t",
			nil_value: '',
		}
		load_all_to_cache()
		a,b = compare(
			CSV.read(ARGV.length == 1 ? LOG_FILE_PATH : ARGV.first, **csv_options),
			CSV.read(ARGV.last, **csv_options)
		).map do |x|
			x.transform_values do |a|
				a.map do |a|
					cached = CACHE.fetch(a[0].to_i, {})
					next unless season.nil? or cached.fetch('start_season', {}) == season
					"0\t#{MAL_PREFIX}#{a[0]}\t#{cached.fetch('title','-')}\t#{cached.fetch('start_date','-')}"
				end.compact
			end
		end
		[a,b].map{|x|x.default = []}

		puts "want:", (a["want"] & b["want"]).sort
		puts "want/ok:", (a["okay"] & b["want"] + a["want"] & b["okay"]).sort
		puts "okay:", (a["okay"] & b["okay"]).sort
		puts "nope/want:", (a["nope"] & b["want"]).sort
		puts "want/nope:", (a["want"] & b["nope"]).sort
	elsif ARGV.first == 'search' && ARGV.length >= 2
		res = cache_search(ARGV[1..].join(' '))
		if res.one?
			puts res.first[1].sort.map{|v| v.join(":\t")}
		else
			date = Time.now.to_i
			puts res.map{|k,v|
				season = v['start_season'].fetch_values('year','season') rescue ['','']
				[k,*season,'-', date, v["title"], v["alternative_titles"]&.fetch('ja','')]
			}.sort_by(&:first).map{|a| a.join("\t")}
		end
	elsif ARGV.length == 2
		if ARGV.first == 'show'
			load_all_to_cache
			puts CACHE[ARGV[1].to_i].sort.map{|v| v.join(":\t")}
		else
			MALinder.new(*ARGV).run()
		end
	else
		puts 'give me year and season'
		puts 'season is one of: winter, spring, summer, fall'
		puts ''
		puts 'alternatively'
		puts '  search <search> [string] ...: to search for something in the local cache'
		puts '  show <id>: to lookup an entry'
		puts '  results [a_log] <b_log> [year season]: compare and find out things both want'
		puts '    limits by season and year if given'
	end
end
