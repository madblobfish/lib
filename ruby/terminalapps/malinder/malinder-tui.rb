require_relative 'malinder-base.rb'

require_optional(__dir__ + '/../lib/gamelib'){
	class TerminalGame
		def run
			raise 'missing ./lib/gamelib'
		end
	end
}

class MALinder < TerminalGame
	UNDO_BUFFER = []
	def inspect #reduce size of errors
		'#<MALinder>'
	end
	def initialize(year_or_ids, season=false, cache_preloaded=true, **opts)
		@fps = :manual
		@first_write = true
		@require_kitty_graphics = true
		@hide_other = opts.fetch(:hide_other, false)
#		@show_overflow = true

		raise 'not supported' unless year_or_ids.is_a?(Array)
		load_all_to_cache() unless cache_preloaded
		@season = CACHE_FULL.fetch_values(*year_or_ids)
		if @season.empty?
			STDERR.puts('all marked or nothing here')
			exit(0)
		end
		@current = 0
	end
	def size_change_handler;sync_draw{draw(true)};end #redraw on size change

	def draw(redraw=false)
		raise TerminalGameEnd, 'empty (all marked or nothing here)' if @season.empty?
		anime = @season[@current]
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
				unless anime['alternative_titles']['ja'].contains_japanese?
					bold()
					print(get_color_code([255,255,0]) + anime['alternative_titles']['ja'].center(@cols - overlength))
					print(color_reset_code())
				else
					print(text_color_bad_words(anime['alternative_titles']['ja'].center(@cols - overlength)))
				end
			end
		else
			print(normal_title)
		end
		print("\r\n"*2)
		paragraph = anime['synopsis'] + "\n"
		paragraph += "\nType: #{anime['media_type']}" if anime['media_type']
		paragraph += "\nSource: #{anime['source']}" if anime['source']
		paragraph += "\nStatus: #{anime['status']}" if anime['status']
		paragraph += "\nStart: #{anime['start_date']}" if anime['start_date']
		paragraph += "\nEpisodes: #{anime['num_episodes']}" if anime['num_episodes'] and anime['num_episodes'] != 0
		if anime['average_episode_duration']
			paragraph += "\nDuration: #{Duration.new(anime['average_episode_duration']).to_s}"
			paragraph += ", total: #{Duration.new(anime['average_episode_duration'].to_i * anime['num_episodes'].to_i).to_s}"
		end
		paragraph += "\nScore: #{anime['mean']}" if anime['mean']
		paragraph += "\nGenres: #{anime['genres'].join(', ')}" if anime['genres']
		paragraph += "\n\nLink: #{MAL_PREFIX}#{anime['id']}"
		paragraph += "\n\nState: #{CHOICES[anime['id'].to_s]['state']}" if CHOICES.has_key?(anime['id'].to_s)
		others = CHOICES_OTHERS.select{|name, choices| choices.has_key?(anime['id'].to_s)}
		if others.any? && !@hide_other
			separator = "\n  "
			paragraph += "\n\nOthers:" + separator
			paragraph += others.map{|name, choices| "#{name}: #{choices[anime['id'].to_s]['state']}" }.join(separator)
		end
		related = fetch_related(anime['id']) rescue ''
		if related.is_a?(String)
			paragraph += "\n\nRelated:\n  #{related}"
		elsif related == []
			paragraph += "\n\nRelated:\n  Nothing"
		elsif related.any?
			separator = "\n  "
			paragraph += "\n\nRelated:" + separator
			paragraph += related.map do |rel|
				rel['entry'].map do |r|
					id = r['mal_id']
					cache = CACHE[id] if r['type'] == 'anime'
					title = r['name']
					# color pattern:
					## yellow when not in CACHE
					## redish/orange when default filterd (in full cache)
					## white when in CACHE
					## gray when not an anime
					color = [180,180,0]
					color = [200,100,60] if CACHE_FULL.has_key?(id)
					if cache
						title = cache.fetch('alternative_titles', {})['en'] rescue nil
						title ||= cache['title']
						color = [255] * 3
					end
					choice = CHOICES.fetch(id.to_s, {}).fetch('state', '-')
					if r['type'] != 'anime'
						choice = '-'
						color = [150] * 3
					end
					url_prefix = MAL_PREFIX
					url_prefix = MAL_MANGA_PREFIX if r['type'] == 'manga'
					[get_color_code(color) + url_prefix + id.to_s, choice, rel['relation'], title + color_reset_code].join("\t")
				end
			end.join(separator)
		end
		if not VIPS
			paragraph += "\n\n\nNote: ruby-vips not installed => graphics are not displayed"
		elsif image(anime, true)
			paragraph = break_lines(text_color_bad_words(paragraph), @cols/2+1)
		else
			paragraph = "#{break_lines(text_color_bad_words(paragraph), @cols)}\n\n\nCould not load image"
		end
		print(paragraph.gsub(/\n(\s*\n)+/, "\n\n").gsub(/\n/, "\r\n"))
		move_cursor(0,0)
		if VIPS
			begin
				current_img = image(anime)
				scale_by = current_img.size.zip([@size_x/2, @size_y]).map{|want,have| want > have ? have/want.to_f : 1}.min
				imgid = kitty_graphics_img_load((scale_by == 1 ? current_img : current_img.resize(scale_by)).pngsave_buffer)
				kitty_graphics_img_pixel_place_center(imgid, *current_img.size.map{|e| (e*scale_by).to_i}, (@size_x/4).to_i, 0)
			rescue RuntimeError => e
				raise unless e.message.start_with?('Could not load image for: ')
			end
		end
		if anime['symbols']
			move_cursor(0,0)
			print(anime['symbols'])
		end

		# print("\r\n")
		# kitty_graphics_img_display(imgid)
	rescue
		raise "current anime id: #{anime['id']}"
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
		when 'r', 'R'
			related = fetch_related(@season[@current]['id'], true)
			if related.is_a?(String)
				print("\t#{related}")
				return
			end
			already_seen = UNDO_BUFFER.select{|e| e[:type]==:log}.map{|e| e[:anime]['id'] }
			animes = related.flat_map{|r|
				r['entry']
					.reject{|e| e['type'] != 'anime'}
					.reject{|e| @season.map{|a|a['id']}.include?(e['mal_id'])}
					.reject{|e| CHOICES.has_key?(e['mal_id'].to_s) if input == 'r'}
					.reject{|e| already_seen.include?(e['mal_id'])}
			}.uniq.map{|e| (input == 'r' ? CACHE : CACHE_FULL)[e['mal_id']]}.compact
			if animes.empty?
				print("\rnothing found or already in choices")
				return
			end
			@season.insert(@current, *animes)
			UNDO_BUFFER << {
				animes: animes,
				type: :related,
				pos: @current,
			}
		when '1'
			logchoice('nope')
		when '2'
			logchoice('okay')
		when '3'
			logchoice('want')
		when "\e[15~"
			# empty, this triggers the redraw below this block
		when 'u'
			if undo = UNDO_BUFFER.pop
				case undo[:type]
				when :log
					LOG_FILE.truncate(LOG_FILE.size() - undo[:bytes])
					@season.insert(undo[:pos], undo[:anime])
					@current = undo[:pos]
				when :related
					undo[:animes].length.times{@season.delete_at(undo[:pos])}
					@current = undo[:pos]
				else
					print("\rthis is a bug!")
				end
			end
		else
			return
		end
		draw
	end

	def logchoice(choice)
		anime = @season[@current]
		return if CHOICES.has_key?(anime['id'].to_s)
		lock_logfile() if @first_write # sorry to exit for now
		written_bytes = add_log_entry(anime, choice)
		@season.delete_at(@current)
		exit() if @season.empty?
		UNDO_BUFFER << {
			anime: anime,
			type: :log,
			bytes: written_bytes,
			pos: @current,
		}
		@current %= @season.size
	end

	def text_color_bad_words(text)
		text.gsub(BAD_WORDS_REGEX){|w| get_color_code([255,0,0]) + w + color_reset_code()}
	end
end
