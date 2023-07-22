HELP_TEXT = []
HELP_TEXT << 'Commands:'
HELP_TEXT << '  <year> <season>: run an interactive malinder Terminal UI, decide what you want'
HELP_TEXT << '      season is one of: winter, spring, summer, fall'
HELP_TEXT << '      controls: arrow keys, q to quit, 1 for nope, 2/a is ok, 3/y is want'
HELP_TEXT << ''
HELP_TEXT << '  stats [--by-season]: get some statistics'
HELP_TEXT << '  show <id>: lookup an entry from cache'
HELP_TEXT << '  search <name>: fuzzy search on "names" in the cache'
HELP_TEXT << '  query <querysyntax>: search cache using expressions'
HELP_TEXT << '      e.g.: (state == seen && year < 1992) || title has Gintama && genres all action,time_travel'
HELP_TEXT << '  log <id/search> <status>: change the status of an anime'
HELP_TEXT << '      adds the episode count if status is just seen'
HELP_TEXT << '      adds "partial," if status is a number'
HELP_TEXT << '      rewrites the entire log file!'
HELP_TEXT << '  results [a_log] <b_log> [year season|querysyntax]: find out common wants'
HELP_TEXT << '      limits by year and season if given'
HELP_TEXT << '      e.g.: someguy.log 2013 summer'
HELP_TEXT << '      e.g.: /tmp/some.log "(year <= 2019) && type != movie"'
HELP_TEXT << ''
HELP_TEXT << '  -i, --interactive may make it show results in the interactive Terminal UI'
HELP_TEXT << '  --json may output json instead'

if __FILE__ == $PROGRAM_NAME
	if ARGV.include?('--help') || ARGV.empty?
		puts HELP_TEXT
		exit 0
	end

	OPTIONS = {
		interactive: ARGV.delete('--interactive') || ARGV.delete('-i'),
		no_default_filter: ARGV.delete('--no-default-filter'),
		json: ARGV.delete('--json'),
	}
	GC.disable
	require_relative 'malinder-base.rb'
	require_relative 'malinder-tui.rb'
	load_all_to_cache
	GC.enable

	if ARGV.first == 'results' && (2..4).include?(ARGV.length)
		ARGV.shift
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
		a,b = compare(
			parse_choices(ARGV.length == 1 ? LOG_FILE_PATH : ARGV.first),
			parse_choices(ARGV.last),
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

		res = {
			'want:'=> (a['want'] & b['want']).sort,
			'want/ok & ok/want:'=> ((a['okay'] & b['want']) + (a['want'] & b['okay'])).sort,
			'okay:'=> (a['okay'] & b['okay']).sort,
			'nope/want:'=> (a['nope'] & b['want']).sort,
			'want/nope:'=> (a['want'] & b['nope']).sort,
			'nil/*'=> (bids - (aids & bids)).sort,
			'*/nil'=> (aids - (aids & bids)).sort,
		}
		if OPTIONS[:json]
			puts JSON.pretty_generate(res)
		else
			res.each{|k,v| puts '' if k == 'nil/*'; puts k, v}
		end
	elsif ARGV.first == 'log' && ARGV.length == 3
		ARGV.shift # throw away first argument
		nime = begin
			CACHE[Integer(ARGV.first, 10)]
		rescue
			res = cache_query("names like '#{ARGV.first}'")
			raise 'not unique or not found, test with "search" first' unless res.one?
			res.first.last
		end
		if nime.nil?
			nime = {
				'id': Integer(ARGV.first, 10),
				'start_season' => {'year'=>'', 'season'=>''}
			}
		end
		log_value = if (Integer(ARGV.last, 10) rescue false)
			'partly,' + ARGV.last
		else
			ARGV.last
		end
		if nime['num_episodes'].to_i < log_value.split(',',2).last.to_i
			raise 'log episode higher than number of episodes'
		elsif nime['num_episodes'].to_s == log_value.split(',',2).last || log_value == 'seen'
			log_value = 'seen,' + nime['num_episodes'].to_s
			puts "was actually '#{log_value}', I fixed that for you ;)" unless log_value == 'seen'
		end
		found = false
		headers = File.readlines(LOG_FILE).first.split("\t")
		newcontent = File.readlines(LOG_FILE).map do |e|
			if e.start_with?("#{nime['id']}\t")
				raise 'found anime twice!' if found
				found = true
				e = e.split("\t")
				if e[3] == log_value
					puts "already the state"
					exit 0
				end
				e[3] = log_value
				e.join("\t")
			else
				e
			end
		end
		if found
			File.write(LOG_FILE, newcontent.join(''))
		else
			LOG_FILE.write("#{nime['id']}\t#{nime['start_season'].fetch_values('year', 'season').join("\t")}\t#{log_value}\t#{Time.now.to_i}\t#{nime['title']}\n")
			puts 'created new entry'
		end
	elsif ARGV.first == 'query' || (ARGV.first == 'search' && ARGV.length >= 2)
		mode = ARGV.shift # throw away first argument
		if mode == 'search'
			res = cache_query("names like '#{ARGV.join(' ')}'")
		else
			res = cache_query(ARGV.join(' '))
		end
		if OPTIONS[:interactive]
			MALinder.new(res.map{|a|a["id"]}.sort()).run()
		elsif OPTIONS[:json]
			puts JSON.pretty_generate(res)
		else
			puts res.map{|nime|
				nime.fetch_values('id', 'year', 'season', 'state', 'timestamp', 'title', 'c1').compact
			}.sort_by(&:first).map{|a| a.join("\t")}
		end
	elsif ARGV.first == 'stats'
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
	elsif ARGV.first == 'show' && ARGV.length == 2
		id = Integer(ARGV[1], 10)
		if OPTIONS[:interactive]
			MALinder.new([id]).run
		else
			res = CACHE_FULL.fetch(id)
			choice = CHOICES[id.to_s][:choice] rescue '-'
			if OPTIONS[:json]
				res['choice'] = choice
				puts JSON.pretty_generate(res)
			else
				puts res.sort.map{|(k,v)|
					next if %w(choice state names start_season).include?(k)
					if k == 'genres'
						[k,v.join(', ')].join(":\t")
					else
						[k,v].join(":\t")
					end
				}.compact
				puts '', "Choice: #{choice}"
			end
		end
	elsif ARGV.length == 2
		MALinder.new(*ARGV).run()
	else
		puts 'unknown command, or wrong parameters.', '', HELP_TEXT
		exit 1
	end
end
