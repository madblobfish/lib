HELP_TEXT = []
HELP_TEXT << 'Commands:'
HELP_TEXT << '  <year> <season>: run an interactive malinder Terminal UI, decide what you want'
HELP_TEXT << '      season is one of: winter, spring, summer, fall'
HELP_TEXT << '      controls: arrow keys, q to quit, 1 for nope, 2/a is ok, 3/y is want'
HELP_TEXT << ''
HELP_TEXT << '  stats [--by-season]: get some statistics'
HELP_TEXT << '  show <id>: lookup an entry from cache'
HELP_TEXT << '  search <name> [--all]: fuzzy search on "names" in the cache'
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
HELP_TEXT << '  edit [filename]: runs "$EDITOR logfile" or the given file name'
HELP_TEXT << ''
HELP_TEXT << '  pull/push: runs "git pull" or "git pull" in config folder'
HELP_TEXT << '  diff [--cached]: runs "git diff" in config folder, optionally shows added changes'
HELP_TEXT << '  add: runs "git add -p" in config folder'
HELP_TEXT << '  restore: runs "git add -p" in config folder'
HELP_TEXT << '  commit [message]: runs "git commit" in config folder, default message is the current day in iso8601 format'
HELP_TEXT << '  log [-p]: runs "git log" in config folder, optionally with diffs'
HELP_TEXT << ''
HELP_TEXT << '  -i, --interactive may make it show results in the interactive Terminal UI'
HELP_TEXT << '  --prefetch may make it load and cache images and related information'
HELP_TEXT << '  --json may output json instead'
HELP_TEXT << ''
HELP_TEXT << '  -u, --log-suffix allows setting the user'
HELP_TEXT << '  --no-default-filter disables filtering using DEFAULT_FILTER config option'

def output_or_process(id_list, data, formatted_text)
	case OPTIONS
	in {prefetch: a} if a
		raise 'prefetch not supported' if id_list.nil?
		prefetch((id_list.call rescue id_list))
	in {interactive: a} if a
		raise 'interactive not supported' if id_list.nil?
		MALinder.new((id_list.call rescue id_list)).run
	in {json: a} if a
		puts JSON.pretty_generate((data.call rescue data))
	else
		if formatted_text
			puts((formatted_text.call rescue formatted_text))
		else
			raise 'I believe this is a bug'
		end
	end
end

if __FILE__ == $PROGRAM_NAME
	if ARGV.include?('--help') || ARGV.empty?
		puts HELP_TEXT
		exit 0
	end

	def pars_arg(const, flag)
		if ARGV.include?(flag)
			Object.const_set(const, ARGV.delete_at(ARGV.index(flag) + 1))
			ARGV.delete(flag)
		end
	end
	pars_arg(:LOG_SUFFIX, '--log-suffix')
	pars_arg(:LOG_SUFFIX, '-u')
	raise 'wat yo doin?!' if Object.const_defined?(:LOG_SUFFIX) && LOG_SUFFIX.nil?
	OPTIONS = {
		all: ARGV.delete('--all'),
		by_season: ARGV.delete('--by-season'),
		cached: ARGV.delete('--cached'),
		force: ARGV.delete('--force'),
		interactive: ARGV.delete('--interactive') || ARGV.delete('-i'),
		json: ARGV.delete('--json'),
		no_default_filter: ARGV.delete('--no-default-filter'),
		prefetch: ARGV.delete('--prefetch'),
		push: ARGV.delete('--push'),
		recurse: ARGV.delete('--recurse'),
	}
	bad_args = ARGV.select{|a| a.start_with?('-')}
	raise 'unknown argument(s): ' + bad_args.join(', ') if bad_args.any?

	DEFAULT_FILTER = nil if OPTIONS[:no_default_filter]
	GC.disable
	require_relative 'malinder-base.rb'
	require_relative 'malinder-tui.rb'
	load_all_to_cache
	GC.enable

	if ARGV.first == 'results' && (2..4).include?(ARGV.length)
		ARGV.shift
		season = nil
		season_query = ''
		if ARGV.length >= 3
			season = {
				'season' => season_shortcuts(ARGV.pop),
				'year' => Integer(ARGV.pop, 10),
			}
			season_query = " && year == #{season['year']} && season == #{season['season']}"
		end

		require 'csv'
		csv_options = {
			skip_blanks: true,
			# skip_lines: /^#/,
			col_sep: "\t",
			nil_value: '',
		}
		own_file = (ARGV.length == 1 ? LOG_FILE_PATH : ARGV.first)
		other_file = ARGV.last
		a,b = compare(
			parse_choices(own_file),
			parse_choices(other_file),
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
			'want/want'=> (a['want'] & b['want']).sort,
			'want/ok'=> (a['want'] & b['okay']).sort,
			'ok/want'=> (a['okay'] & b['want']).sort,
			# 'want/ok & ok/want'=> ((a['okay'] & b['want']) + (a['want'] & b['okay'])).sort,
			# 'okay'=> (a['okay'] & b['okay']).sort,
			'nope/want'=> (a['nope'] & b['want']).sort,
			'want/nope'=> (a['want'] & b['nope']).sort,
			'-/*'=> (bids - (aids & bids)).sort,
			'*/-'=> (aids - (aids & bids)).sort,
		}
		output_or_process(nil, res, lambda{
			prefixes = [own_file, other_file].map{|p| choices_path_to_prefix(p)}
			res.map do |k,v|
				r = []
				r << '' if k == '-/*'
				r << k.split('/').zip(prefixes)
					.reject{|c,p|c == '*'}
					.map{|c, p| LOG_FILE_PATH.end_with?(p+'.log') ? "choice == #{c}" : "choice-#{p} == #{c}"}
					.join(' && ') + season_query
				r << v
			end
		})
	elsif ARGV.first == 'log' && (ARGV.length == 3 || ARGV.length == 4)
		custom = ARGV.pop.strip if ARGV.length == 4
		ARGV.shift # throw away first argument
		nime = begin
			CACHE_FULL[Integer(ARGV.first, 10)]
		rescue
			res = cache_query("names like '#{ARGV.first}'") rescue []
			# raise 'not unique or not found, test with "search" first' unless res.one?
			if res.one?
				res.first.last
			else
				nil
			end
		end
		if nime.nil?
			nime = {
				'id' => ARGV.first,
				'start_season' => {'year'=>'', 'season'=>''}
			}
		end
		log_value = if (Integer(ARGV.last, 10) rescue false)
			'partly,' + ARGV.last
		else
			ARGV.last
		end
		if nime.fetch('num_episodes', 0) != 0 && nime['num_episodes'] < log_value.split(',',2).last.to_i
			raise 'log episode higher than number of episodes' unless OPTIONS[:force]
		elsif nime['num_episodes'].to_s == log_value.split(',',2).last || log_value == 'seen'
			log_value = 'seen,' + nime['num_episodes'].to_s
			puts "corrected to '#{log_value}' for you :)" unless log_value == 'seen'
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
				if STATE_ACTIVE.include?(log_value) # plain value, no details
					e[3] = log_value + ',' + e[3].split(',',2)[1].to_s # keep status
				else
					e[3] = log_value
				end
				if custom
					e[6] = custom
				else
					if log_value.start_with?('seen')
						if e.length == 7
							e.delete(6)
						else
							e[6] = ''
						end
					end
				end
				e.map{|v| v.include?('"') ? "\"#{v.gsub('"', '""')}\"" : v}.join("\t").tr("\n",'').rstrip + "\n"
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
	elsif (ARGV.first == 'query' || ARGV.first == 'search') && ARGV.length >= 2
		mode = ARGV.shift # throw away first argument
		query = ARGV.join(' ')
		query = "names like '#{query}'" if mode == 'search'
		res = cache_query(query, OPTIONS[:all])
		output_or_process(
			lambda{res.map{|a|a["id"]}.sort()},
			res,
			lambda{
				res.map{|nime|
					nime.fetch_values('id', 'year', 'season', 'state', 'timestamp', 'title', 'c1').compact
				}.sort_by(&:first).map{|a| a.join("\t")}
			}
		)
	elsif ARGV.first == 'stats'
		time_chosen_sum = 0
		count_chosen = 0
		time_watched_sum = 0
		count_watched = 0
		CHOICES.each do |id, v|
			if anime = CACHE_FULL[id.to_i]
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
		if OPTIONS[:by_season]
			puts ''
			CACHE.reject{|k,a| a['media_type'] == 'music'}.group_by{|k,v| v.fetch('start_season', {})}.sort{|a,b|a.first.values <=> b.first.values}.each do |season, nimes|
				print_percent[
					season.values.join(' '),
					nimes.count{|id,_|CHOICES.has_key?(id.to_s)},
					nimes.count
				]
			end
		end
	elsif ARGV.first == 'relations' && ARGV.length == 2
		id = Integer(ARGV[1], 10)
		res = CACHE_FULL.fetch(id)
		related = fetch_related(id)
		if OPTIONS[:recurse]
			seen = [id]
			while search = related.flat_map{|a| a['entry']}.select{|a| a['type'] == 'anime' && ! seen.include?(a['mal_id'])}.first
				rel = fetch_related(search['mal_id'], true)
				if rel == 'Ratelimited: internally'
					STDERR.puts('Results do not yet include all related')
					break
				end
				related += rel
				seen << search['mal_id']
			end
		end
		output_or_process(
			lambda{related.map{|a|a["id"]}.sort()},
			related,
			'well... use --json or --interactive here for now' # no clue how to present this
		)
	elsif ARGV.first == 'show' && ARGV.length == 2
		id = Integer(ARGV[1], 10)
		output_or_process(
			[id],
			lambda{CACHE_FULL.fetch(id)},
			lambda{
				ret = CACHE_FULL.fetch(id).sort.map{|(k,v)|
					next if %w(choice state names start_season).include?(k)
					if k == 'genres'
						[k,v.join(', ')].join(":\t")
					else
						[k,v].join(":\t")
					end
				}.compact
				ret << ['', "Choice: #{CHOICES[id.to_s][:choice] rescue '-'}"]
			}
		)

	elsif ARGV.first == 'edit' && (1..2).include?(ARGV.length)
		filename = ARGV.fetch(1, LOG_FILE_NAME)
		filename = CONFIG_DIR + filename unless filename.include?("/")
		system(ENV.fetch('EDITOR', 'nano'), filename, exception: true)

# git integration
	elsif ARGV == ['add']
		Dir.chdir(CONFIG_DIR) do
			system('git', 'add', '-p', exception: true)
		end
	elsif ARGV == ['pull']
		Dir.chdir("#{CONFIG_DIR}sources/") do
			system('git', 'pull', '--ff-only', exception: true)
		end
		Dir.chdir(CONFIG_DIR) do
			system('git', 'pull', '--ff-only', exception: true)
		end
	elsif ARGV == ['push']
		system({'GIT_DIR'=> "#{CONFIG_DIR}.git"}, 'git', 'push', exception: true)
	elsif ARGV.first == 'commit' && (1..3).include?(ARGV.length)
		require 'date'
		message = ARGV.fetch(1, DateTime.now.strftime('%F'))
		system({'GIT_DIR'=> "#{CONFIG_DIR}.git"}, 'git', 'commit', '-m', message, exception: true)
		system({'GIT_DIR'=> "#{CONFIG_DIR}.git"}, 'git', 'push', exception: true) if OPTIONS['push']
	elsif ARGV.first == 'diff' && ARGV.length == 1
		Dir.chdir(CONFIG_DIR) do
			cmd = 'git', 'diff'
			cmd << '--cached' if OPTIONS[:cached]
			system(*cmd, exception: true)
		end
	elsif ARGV.first == 'log' && (1..2).include?(ARGV.length)
		Dir.chdir(CONFIG_DIR) do
			if ARGV[1] == '-p'
				system('git', 'log', '-p', exception: true)
			elsif ARGV.one?
				system('git', 'log', exception: true)
			else
				raise 'unknown argument'
			end
		end

	elsif ARGV.length == 2
		OPTIONS[:interactive] = true # this command forces interactive use
		year = Integer(ARGV.first, 10) # raises an exception if year is not integer
		season = season_shortcuts(ARGV.last)
		# for checking and better error messages
		raise 'missing json, run malinder.sh first' unless File.exists?("#{CONFIG_DIR}sources/#{year}-#{season}.json")
		output_or_process(
			lambda{cache_query("year == #{year} && season == #{season} && choice == -").map{|a| a['id']} },
			nil, nil
		)

	else
		puts 'unknown command, or wrong parameters.', '', HELP_TEXT
		exit 1
	end
end
