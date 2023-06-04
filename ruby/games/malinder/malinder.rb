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
require_optional(File.dirname(__FILE__) + '/../../stdlib/duration'){
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
require_optional(File.dirname(__FILE__) + '/../lib/gamelib'){
	class TerminalGame
		def run
			raise 'missing ./lib/gamelib'
		end
	end
}

CACHE_DIR = ENV.fetch('XDG_CACHE_HOME', ENV.fetch('HOME') + '/.cache') + '/malinder/'
CONFIG_DIR = ENV.fetch('XDG_CACHE_HOME', ENV.fetch('HOME') + '/.config') + '/malinder/'
require_optional(CONFIG_DIR + '/config.rb')

def configurable_default(name, default)
	Object.const_set(name, default) unless Object.const_defined?(name)
end
# configurable_default
configurable_default(:API, 'https://api.myanimelist.net/v2/')
FileUtils.mkdir_p(CACHE_DIR + 'images/')
configurable_default(:LOG_SUFFIX, '-' + ENV['USER'])
configurable_default(:LOG_FILE_PATH, "#{CONFIG_DIR}choices#{LOG_SUFFIX}.log")
configurable_default(:BAD_WORDS,
	%w(
		mini idol cultivat mini chibi promotion game pokemon sport mecha machine limited trailer short season
		special extra harem hentai ecchi kids collaboration commercial precure reborn rebirth revive isekai
		reincar sanrio compilation transformer
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
CHOICES = Hash[LOG_FILE.each_line.drop(1).map{|l| id, y, s, c, ts = l.split("\t"); [id, {choice:c, ts: ts}]}]
MAL_PREFIX = 'https://myanimelist.net/anime/'

def load_all_to_cache()
	Dir[CONFIG_DIR + 'sources/*'].each do |s|
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
	raise "#{ret.code} - #{url}" if ret.code != '200'
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
		begin
			image = fetch(url).body
		rescue
			raise "#{id}"
		end
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
		season_file = "#{CONFIG_DIR}sources/#{year}-#{season}.json"
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
		)
		(a, aids),(b, bids) = [[a, []],[b, []]].map do |x, ids|
			[x.transform_values do |a|
				a.map do |a|
					cached = CACHE.fetch(a[0].to_i, {})
					next unless season.nil? or cached.fetch('start_season', {}) == season
					ids << a[0]
					"0\t#{MAL_PREFIX}#{a[0]}\t#{cached.fetch('title','-')}\t#{cached.fetch('start_date','-')}"
				end.compact
			end, ids]
		end
		[a,b].map{|x|x.default = []}

		puts 'want:', (a['want'] & b['want']).sort
		puts 'want/ok:', ((a['okay'] & b['want']) + (a['want'] & b['okay'])).sort
		puts 'okay:', (a['okay'] & b['okay']).sort
		puts 'nope/want:', (a['nope'] & b['want']).sort
		puts 'want/nope:', (a['want'] & b['nope']).sort
		puts '', 'nil/*', (bids - (aids & bids)).sort
		puts '*/nil', (aids - (aids & bids)).sort
	elsif ARGV.first == 'log' && ARGV.length == 3
		ARGV.shift #throw away first argument
		load_all_to_cache
		nime = begin
			CACHE[Integer(ARGV.first, 10)]
		rescue
			res = cache_search(ARGV.first)
			raise 'not unique or not found, test with "search" first' unless res.one?
			res.first.last
		end
		found = false
		headers = File.readlines(LOG_FILE).first.split("\t")
		newcontent = File.readlines(LOG_FILE).map do |e|
			if e.start_with?("#{nime['id']}\t")
				raise 'found anime twice!' if found
				found = true
				e = e.split("\t")
				e[3] = ARGV.last
				e[3] += ',' + nime['num_episodes'].to_s if ARGV.last == 'seen'
				e.join("\t")
			else
				e
			end
		end
		if found
			File.write(LOG_FILE, newcontent.join(''))
		else
			LOG_FILE.write("#{nime['id']}\t#{nime['start_season'].fetch_values('year', 'season').join("\t")}\t#{ARGV.last}\t#{Time.now.to_i}\t#{nime['title']}\n")
			puts 'created new entry'
		end
	elsif ARGV.first == 'search' && ARGV.length >= 2
		res = cache_search(ARGV[1..].join(' '))
		if res.one?
			puts res.first[1].sort.map{|v| v.join(":\t")}
			puts '', "Choice: #{CHOICES[res.first[1]['id'].to_s][:choice] rescue '-'}"
		else
			date = Time.now.to_i
			puts res.map{|k,v|
				old = CHOICES.fetch(v['id'].to_s, {})
				season = v['start_season'].fetch_values('year','season') rescue ['','']
				[k,*season, old.fetch(:choice, '-'), old.fetch(:ts, date), v['title'], v['alternative_titles']&.fetch('ja','')]
			}.sort_by(&:first).map{|a| a.join("\t")}
		end
	elsif ARGV.first == 'query'
		require_relative '../../stdlib/array/query'
		ARGV.shift #throw away first argument
		load_all_to_cache
		date = Time.now.to_i
		x = CACHE.map do |k, v|
			v['choice'] = '-'
			v['timestamp'] = date
			if CHOICES.has_key?(k.to_s)
				v['state'] = CHOICES[k.to_s][:choice].split(',').first
				v['choice'] = CHOICES[k.to_s][:choice]
				v['timestamp'] = CHOICES[k.to_s][:ts]
			end
			v.merge!(v['start_season'])
			v['genres'] = v['genres']&.map{|h|h['name'].downcase.tr(' ', '_')}
			v
		end
		puts x.query(ARGV.join(' ')).map{|nime|
			nime.fetch_values('id', 'year', 'season', 'choice', 'timestamp', 'title')
		}.sort_by(&:first).map{|a| a.join("\t")}
	elsif ARGV.first == 'stats'
		load_all_to_cache
		time_chosen_sum = 0
		count_chosen = 0
		time_watched_sum = 0
		count_watched = 0
		CHOICES.each do |id, v|
			if anime = CACHE[id.to_i]
				status, seen_eps = v[:choice].split(',', 2)
				seen_eps ||= anime['num_episodes'] if status == 'seen'
				if %w(paused partly broken seen).include?(status)
					time_watched_sum += seen_eps.to_i * anime.fetch('average_episode_duration', 0)
					count_watched += 1 if %w(broken seen).include?(status)
				end
				unless %w(nope okay).include?(status)
					eps = anime['num_episodes']
					eps = seen_eps unless status == 'broken'
					time_chosen_sum += eps.to_i * anime.fetch('average_episode_duration', 0)
					count_chosen += 1
				end
			else
				STDERR.puts 'could not resolve: ' + id unless id.start_with?('imdb,')
			end
		end
		CHOICES.map{|k,v|v[:choice].split(',').first}.group_by{|e|e}.map{|a,b|[a,b.count]}.map{|e| puts e.join(': ') }
		puts ''
		print_percent = lambda do |name, part, full|
			puts("%s ratio:\t%2.2f%% (%d of %d)" % [name, part*100.0/full, part, full])
		end
		print_percent['Watched', count_watched, count_chosen]
		print_percent['Watched time', time_watched_sum, time_chosen_sum]
		print_percent['Tracked', CHOICES.size, CACHE.size]
		if ARGV.include?('--by-season')
			puts ''
			CACHE.reject{|k,a| a['media_type'] == 'music'}.group_by{|k,v| v['start_season']}.sort{|a,b|a.first.values <=> b.first.values}.each do |season, nimes|
				print_percent[
					season.values.join(' '),
					nimes.count{|id,_|CHOICES.has_key?(id.to_s)},
					nimes.count
				]
			end
		end
	elsif ARGV.length == 2
		if ARGV.first == 'show'
			load_all_to_cache
			puts CACHE.fetch(ARGV[1].to_i).sort.map{|(k,v)|
				if k == 'genres'
					[k,v.map{|k|k['name']}.sort.join(', ')].join(":\t")
				else
					[k,v].join(":\t")
				end
			}
			puts '', "Choice: #{CHOICES[ARGV[1]][:choice] rescue '-'}"
		else
			MALinder.new(*ARGV).run()
		end
	else
		puts 'Commands:'
		puts '  <year> <season>: run interactive malinder, decide what you want'
		puts '    season is one of: winter, spring, summer, fall'
		puts '    controls: arrow keys, q to quit, 1 for nope, 2/a is ok, 3/y is want'
		puts ''
		puts '  stats: get some statistics'
		puts '  show <id>: lookup an entry from cache'
		puts '  search <search> [string] ...: fuzzy search on names in the cache'
		puts '  query <querysyntax>: search cache using expressions'
		puts '    e.g.: (state == seen && year < 1992) || title has Gintama && genres all action,time_travel'
		puts '  log <id/search> <status>: change the status of an anime'
		puts '    this adds the episode count if status is just seen'
		puts '    this command rewrites the entire log file!'
		puts '  results [a_log] <b_log> [year season]: find out common wants'
		puts '    limits by season and year if given'
	end
end
