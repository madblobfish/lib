require_relative 'lib/gamelib'
require 'net/http'
require 'json'
require 'vips'
require 'fileutils'

API = 'https://api.myanimelist.net/v2/'
CACHE_DIR = ENV.fetch('XDG_CACHE_HOME', ENV.fetch('HOME') + '/.cache') + '/malinder/'
FileUtils.mkdir_p(CACHE_DIR + 'images/')
IMAGE_CACHE = {}
LOG_FILE_PATH = CACHE_DIR + 'choices.log'
LOG_FILE = File.open(LOG_FILE_PATH, "a+")
LOG_FILE.sync = true
CHOICES = Hash[LOG_FILE.each_line.map{|l| id, c, ts = l.split("\t"); [id, {choice:c, ts: ts}]}]
CACHE = {}
CACHE_BY_RANK = {}
BAD_WORDS = %w(
	mini idol cultivat mini chibi promotion game pokemon sport mecha machine limited trailer short season
	special extra harem ecchi kids collaboration commercial precure reborn rebirth revive isekai
)	+ ['love live']
BAD_WORDS_REGEX = /\b#{ Regexp.union(BAD_WORDS).source }\b/i

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
	CACHE.select do |k,v|
		[v["title"], *v["alternative_titles"]&.values].flatten.any?{|s| s.match?(/#{needle}/i)}
	end.map{|k,v| [k, v["title"], v["alternative_titles"]&.fetch('ja','')]}
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
# fetch(j["main_picture"]["large"])

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

class MALinder < TerminalGame
	SEASON_SHORTCUTS = {'w': 'winter', 'sp': 'spring', 'su': 'summer', 'f': 'fall'}
	def initialize(year, season)
		@fps = :manual
		@require_kitty_graphics = true
#		@show_overflow = true

		season = SEASON_SHORTCUTS.fetch(season, season)
		raise 'invalid season' unless SEASON_SHORTCUTS.values.include?(season)
		year = Integer(year, 10) # raise if year is not an integer
		@which_season = [year, season]
		season_file = "#{CACHE_DIR}sources/#{year}-#{season}.json"
		raise 'missing json, run malinder.sh first' unless File.exists?(season_file)
		@season = JSON.parse(File.read(season_file))['data'].map{|v|v['node']}
		@season.reject!{|a| CHOICES.has_key?(a["id"].to_s)}
		@season.reject!{|a| a["media_type"] == "music"}
		@season.select!{|a| a["start_season"]["year"] == year}
#		@season.select!{|a| a["nsfw"] == "white"}
		raise 'empty (all marked or nothing here)' if @season.empty?
		@current = 0
	end
	def size_change_handler;sync_draw{draw(true)};end #redraw on size change

	def draw(redraw=false)
		raise 'empty (all marked or nothing here)' if @season.empty?
		anime = @season[@current]
		current_img = image(anime)
		scale_by = current_img.size.zip([@size_x/2, @size_y]).map{|want,have| want > have ? have/want.to_f : 1}.min
		buffer = (scale_by == 1 ? current_img : current_img.resize(scale_by)).pngsave_buffer
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
				overlength = anime['alternative_titles']["ja"].gsub(/[0-9a-z\/+_-]/i, '').length
				print(text_color_bad_words((anime['alternative_titles']["ja"]).center(@cols - overlength)))
			end
		else
			print(normal_title)
		end
		print("\r\n"*2)
		paragraph = anime['synopsis'] + "\n"
		paragraph += "\nType: #{anime['media_type']}" if anime['media_type']
		paragraph += "\nSource: #{anime['source']}" if anime['source']
		paragraph += "\nEpisodes: #{anime['num_episodes']}" if anime['num_episodes'] and anime['num_episodes'] != 0
		paragraph += "\nGenres: #{anime['genres'].map{|x|x['name']}.join(', ')}" if anime['genres']
		paragraph += "\n\nLink: https://myanimelist.net/anime/#{anime['id']}"
		paragraph = text_color_bad_words(paragraph).split("\n").map{|l|l.each_char.each_slice(@cols/2).map(&:join).join("\n")}.join("\n")
		print(paragraph.gsub(/\n(\s*\n)+/, "\n\n").gsub(/\n/, "\r\n"))
		move_cursor(0,0)
		imgid = kitty_graphics_img_load(buffer)
		kitty_graphics_img_pixel_place_center(imgid, *current_img.size.map{|e| (e*scale_by).to_i}, (@size_x/4).to_i, 0)
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
		when "\e" #quit
			exit()
		when '1', 'q'
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
		LOG_FILE.write("#{anime["id"]}\t#{@which_season.join("\t")}\t#{choice}\t#{Time.now.to_i}\t#{anime['title']}\n")
		@season.delete_at(@current)
		exit() if @season.empty?
		@current %= @season.size
	end

	def text_color_bad_words(text)
		text.gsub(BAD_WORDS_REGEX){|w| get_color_code([255,0,0]) + w + color_reset_code()}
	end
end

if __FILE__ == $PROGRAM_NAME
	if ARGV.length == 2
		MALinder.new(*ARGV).run()
	else
		puts 'give me year and season'
		puts 'season is one of: winter, spring, summer, fall'
	end
end
