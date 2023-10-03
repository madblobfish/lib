require_relative 'malinder-base.rb'

require_optional(__dir__ + '/../lib/gamelib'){
	class TerminalGame
		def run
			raise 'missing ./lib/gamelib'
		end
	end
}

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
def fetch_related(id)
	return [] if id.to_s.start_with?('imdb,')
	return [] if id.to_i == 0
	cached_file = CACHE_DIR_RELATIONS + id.to_i.to_s + '.json'
	if File.exists?(cached_file)
		related = File.read(cached_file)
	else
		# backoff a bit to not run into ratelimits
		return 'Ratelimited: internally' if Time.now - File.mtime("#{CACHE_DIR_RELATIONS}") >= 1
		related = fetch("https://api.jikan.moe/v4/anime/#{id.to_i}/relations").body
		File.write(cached_file, related)
	end
	JSON.parse(related).fetch('data')
rescue RuntimeError => e
	raise unless e.start_with?('429 - ')
	'Ratelimited: got Error 429'
end
# fetch(API + 'anime/30230')
# fetch(j['main_picture']['large'])

def image(anime)
	id = anime['id']
	return IMAGE_CACHE[id] if IMAGE_CACHE.has_key?(id)
	path = CACHE_DIR_IMAGES + id.to_i.to_s + '.png'
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

class MALinder < TerminalGame
	SEASON_SHORTCUTS = {
		'w'=> 'winter', 'sp'=> 'spring', 'su'=> 'summer', 'f'=> 'fall',
		'1'=> 'winter', '2'=> 'spring', '3'=> 'summer', '4'=> 'fall',
	}
	def inspect #reduce size of errors
		'#<MALinder>'
	end
	def initialize(year_or_ids, season=false)
		@fps = :manual
		@require_kitty_graphics = true
#		@show_overflow = true

		load_all_to_cache()
		if year_or_ids.is_a?(Array)
			@season = CACHE_FULL.fetch_values(*year_or_ids)
		else
			year = year_or_ids
			raise "season not given" if season == false
			season = season_shortcuts(season)
			year = Integer(year, 10) # raise if year is not an integer
			# this stays just for checking and better error messages
			season_file = "#{CONFIG_DIR}sources/#{year}-#{season}.json"
			raise 'missing json, run malinder.sh first' unless File.exists?(season_file)
			@season = cache_query("year == #{year} && season == #{season} && choice == -")
		end
		if @season.empty?
			STDERR.puts('all marked or nothing here')
			exit(0)
		end
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
		paragraph += "\nScore: #{anime['mean']}" if anime['mean']
		paragraph += "\nGenres: #{anime['genres'].join(', ')}" if anime['genres']
		paragraph += "\n\nLink: #{MAL_PREFIX}#{anime['id']}"
		paragraph += "\n\nCHOICE: #{CHOICES[anime['id'].to_s][:choice]}" if CHOICES.has_key?(anime['id'].to_s)
		others = CHOICES_OTHERS.select{|name, choices| choices.has_key?(anime['id'].to_s)}
		if others.any?
			separator = "\n  "
			paragraph += "\n\nOthers:" + separator
			paragraph += others.map{|name, choices| "#{name}: #{choices[anime['id'].to_s][:choice]}" }.join(separator)
		end
		related = fetch_related(anime['id'])
		if related.is_a?(String)
			paragraph += "\n\nRelated:\n  #{related}"
		elsif related == []
			paragraph += "\n\nRelated:\n  Nothing"
		elsif related.any?
			separator = "\n  "
			paragraph += "\n\nRelated:" + separator
			paragraph += related.map do |rel|
				id = rel['entry'].first['mal_id']
				cache = CACHE[id]
				choice = CHOICES.fetch(id.to_s, {}).fetch(:choice, '-')
				title = rel['entry'].first['name']
				if cache
					title = cache.fetch('alternative_titles', {})['en'] rescue nil
					title ||= cache['title']
				end
				url_prefix = MAL_PREFIX
				url_prefix = MAL_MANGA_PREFIX if rel['entry'].first['type'] == 'manga'
				[url_prefix + id.to_s, choice, rel['relation'], title].join("\t")
			end.join(separator)
		end
		if VIPS
			paragraph = break_lines(text_color_bad_words(paragraph), @cols/2+1)
		else
			paragraph += "\n\n\nNote: ruby-vips not installed => graphics are not displayed"
		end
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
		return if CHOICES.has_key?(anime['id'].to_s)
		which_season = anime['start_season'].fetch_values('year', 'season')
		LOG_FILE.write("#{anime['id']}\t#{which_season.join("\t")}\t#{choice}\t#{Time.now.to_i}\t#{anime['title']}\n")
		@season.delete_at(@current)
		exit() if @season.empty?
		@current %= @season.size
	end

	def text_color_bad_words(text)
		text.gsub(BAD_WORDS_REGEX){|w| get_color_code([255,0,0]) + w + color_reset_code()}
	end
end

