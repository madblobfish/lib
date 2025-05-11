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
HELP_TEXT << '  db-pfusch [--help]: merge or normalize choices'
HELP_TEXT << '      see its own help for more details'
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
HELP_TEXT << '  fix-names: try to guess the ID and rename files'
HELP_TEXT << '  clean: cleanup already seen'
HELP_TEXT << '  missing: list missing episodes in current dir'
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
		prefetch((id_list.is_a?(Proc) ? id_list.call : id_list))
	in {interactive: a} if a
		raise 'interactive not supported' if id_list.nil?
		MALinder.new((id_list.is_a?(Proc) ? id_list.call : id_list)).run
	in {json: a} if a
		puts JSON.pretty_generate((data.is_a?(Proc) ? data.call : data))
	in {text: a} if a
		puts((formatted_text.is_a?(Proc) ? formatted_text.call : formatted_text))
	else
		if formatted_text
			puts((formatted_text.is_a?(Proc) ? formatted_text.call : formatted_text))
		else
			raise 'I believe this is a bug'
		end
	end
end

if __FILE__ == $PROGRAM_NAME
	DB_PFUSCH = ARGV.first == 'db-pfusch'
	if (ARGV.include?('--help') && !DB_PFUSCH) || ARGV.empty?
		puts HELP_TEXT
		exit 0
	end
	ARGV_ORIGINAL = ARGV.map{|e| e.dup}

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
		text: ARGV.delete('--text'),
		recurse: ARGV.delete('--recurse'),
	}
	bad_args = ARGV.select{|a| a.start_with?('-')}
	raise 'unknown argument(s): ' + bad_args.join(', ') if bad_args.any? && !DB_PFUSCH
	DEFAULT_FILTER = nil if OPTIONS[:no_default_filter]
	require_relative 'malinder-base.rb'


	# makes commands faster which do not need cached data
	didcommand = true
	if ARGV.first == 'edit' && (1..2).include?(ARGV.length)
		filename = ARGV.fetch(1, LOG_FILE_NAME)
		filename = CONFIG_DIR + filename unless filename.include?("/")
		system(ENV.fetch('EDITOR', 'nano'), filename, exception: true)
	elsif ARGV.first == 'db-pfusch'
		exec("ruby", "#{__dir__}/malinder-db-pfusch.rb", *ARGV_ORIGINAL.drop(1))

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
		system({'GIT_DIR'=> "#{CONFIG_DIR}.git"}, 'git', 'push', exception: true) if OPTIONS[:push]
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
	else
		didcommand = false
	end
	exit 0 if didcommand

	GC.disable
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
			raise "unknown anime state (want,okay,...)" unless STATE_LEVEL.keys.include?(ARGV.last.split(',', 2).first)
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
		count_chosen_episodes = 0
		count_watched_episodes = 0
		CHOICES.each do |id, v|
			if anime = CACHE_FULL[id.to_i]
				status, seen_eps, seen_time = v['state'].split(',', 3)
				seen_eps ||= anime['num_episodes'] if status == 'seen'
				if %w(paused partly broken seen).include?(status)
					time_watched_sum += seen_eps.to_i * anime.fetch('average_episode_duration', 0)
					if %w(partly, paused).include?(status)
						count_chosen_episodes += anime['num_episodes'].to_i
					else
						count_chosen_episodes += seen_eps.to_i
					end
					count_watched_episodes += seen_eps.to_i
					count_watched += 1 if %w(broken seen).include?(status)
				end
				unless %w(nope okay).include?(status)
					eps = anime['num_episodes']
					eps = seen_eps if status == 'broken'
					count_watched_episodes += seen_eps.to_i
					count_chosen_episodes += eps.to_i
					time_chosen_sum += eps.to_i * anime.fetch('average_episode_duration', 0)
					count_chosen += 1
				end
			else
				unless id.start_with?('imdb,') || v['state'] == 'nope' || DELETIONS[id]
					STDERR.puts 'could not resolve: ' + id
				end
			end
		end
		puts CHOICES.map{|k,v|v['state'].split(',').first}.group_by{|e|e}.map{|a,b|[a,b.count]}.sort_by{|k,v|v}.map{|e| e.join(': ') }
		puts ''
		puts FAVORITES.group_by{|a,b| b}.map{|k,v| "#{k}: #{v.count}"}
		puts ''
		print_percent = lambda do |name, part, full, print_duration=false|
			if print_duration
				puts("%s ratio:\t%2.2f%% (%s of %s), %s left" % [name, part*100.0/full, *[part, full, full-part].map{|e|Duration.new(e).to_s}])
			else
				puts("%s ratio:\t%2.2f%% (%d of %d), %d left" % [name, part*100.0/full, part, full, full-part])
			end
		end
		print_percent['Watched', count_watched, count_chosen]
		print_percent['Watched Time', time_watched_sum, time_chosen_sum, true]
		print_percent['Watched Episodes ', count_watched_episodes, count_chosen_episodes]
		print_percent['Tracked', CHOICES.size, CACHE.size]
		print_percent['Filtered Cache vs full Cache', CACHE.size, CACHE_FULL.size]
		if OPTIONS[:by_season]
			puts ''
			CACHE.reject{|k,a| a['media_type'] == 'music'}.group_by{|k,v| v.fetch('start_season', {})}.sort{|a,b|a.first.values <=> b.first.values}.each do |season, nimes|
				print_percent[
					season.values.join(' '),
					nimes.count{|id,_| CHOICES.has_key?(id.to_s)},
					nimes.count
				]
			end
		end
	elsif ARGV.first == 'relations' && ARGV.length == 2
		id = Integer(ARGV[1], 10)
		res = CACHE_FULL.fetch(id)
		related = fetch_related(id)
		if OPTIONS[:recurse]
			offline = is_offline?
			seen = [id]
			while search = related.flat_map{|a| a['entry']}.select{|a| a['type'] == 'anime' && ! seen.include?(a['mal_id'])}.first
				rel = fetch_related(search['mal_id'], !offline)
				if rel == 'No internet, lol'
					print '.'
				elsif rel == 'Ratelimited: internally'
					STDERR.puts('Results do not yet include all related')
					break
				else
					related += rel
				end
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
				ret << ['', "State: #{CHOICES[id.to_s]['state'] rescue '-'}"]
			}
		)
	elsif ARGV.first == 'stack' && ARGV.length == 2
		require 'nokogiri'
		require 'open-uri'
		html = URI.open(ARGV.last).read
		doc = Nokogiri::HTML(html)
		links = doc.css('.seasonal-anime')
			.map{|e| e.css('.title a').first['href']}
			.map{|l| /^https:\/\/myanimelist\.net\/anime\/([0-9]+)\//.match(l) ? $1.to_i : nil }
			.compact
		links.reject!{|l| CHOICES.has_key?(l.to_s)} unless OPTIONS[:all]
		output_or_process(links, links, links.join("\n"))

	elsif ARGV[0] == 'fetch_related'
		p fetch_related(ARGV[1].to_i).flat_map{|rel|rel['entry']}
		p fetch_related(ARGV[1].to_i).flat_map{|rel|rel['entry'].map{|r| r['mal_id']}}
		p fetch_related(ARGV[1].to_i).flat_map{|rel|rel['entry'].map{|r| CHOICES.fetch(r['mal_id'].to_s, {}).fetch('state', '-')}}

	elsif ARGV == ['clean']
		files = parse_local_files(lambda{|seen,ep| seen >= ep}).values.flatten
		if files.empty?
			puts 'already clean :)'
			exit(0)
		end
		puts 'Will delete:'
		puts files.map(&:inspect)
		puts '[yes/NO]?'
		if STDIN.readline.rstrip() == 'yes'
			files.each{|f| File.delete(f)}
			puts "deleted"
		end
	elsif ARGV == ['fix-names']
		CLEAN_CACHE = {}
		Dir['*{.mkv,.mp4}'].each do |f|
			next if f =~ /^\d+-S\d+E\d+-/
			cleaner = f.gsub(/\[[^\]]+\]\s*/, '').gsub(/\..*$/, '').gsub(/v\d\s*$/, '')
			/S(?<season>\d{1,2})E(?<episod>\d{1,2})/i =~ cleaner
			title, _, episode = cleaner.rpartition('-')
			episode = episod if episod
			series = title.split('-', 2).first.strip
			CLEAN_CACHE[series] ||= cache_query("names like '#{series.tr("'",'')}'")
			# puts "#{f} - #{title.strip}: #{episode}"
			if CLEAN_CACHE[series].length == 1
				newname = "#{CLEAN_CACHE[series].first['id']}-S00E#{episode.strip}-"
				puts "rename: #{f.inspect} with prefix #{newname.inspect}?"
				unless File.exist?(newname + f)
					puts '[y/N]?'
					if STDIN.readline.rstrip() == 'y'
						File.rename(f, newname + f)
						puts "renamed"
					end
				end
			else
				if CLEAN_CACHE[series].length == 0
					puts "could not find the anime"
				else
					puts "can not solve for: #{f}"
					p CLEAN_CACHE[series].map{|a|a['id']}.compact
				end
				puts "searched for: #{series.tr("'",'')}"
				# id = CLEAN_CACHE[series].map{|a|a['id']}.compact.first
			end
		end
	elsif ARGV == ['missing']
		parse_local_files(lambda{|seen,ep| seen < ep}).map do |id, files_existing|
			eps_existing = files_existing.map(&:last)
			num_episodes = CACHE[id].fetch('num_episodes', 0)
			num_episodes = eps_existing.max + 1 if num_episodes == 0
			seen_so_far = CHOICES.fetch(id.to_s, {}).fetch('state', ',0').split(',', 2).last.to_i + 1
			seen_so_far.upto(num_episodes).each do |ep|
				unless eps_existing.include?(ep)
					puts "#{id} is missing ep #{ep} - #{CACHE[id]&.fetch('title', 'name unkown')}"
				end
			end
		end
	elsif ARGV == ['watch']
		files = parse_local_files(lambda{|seen,ep| seen < ep})
		p files

	elsif ARGV.length == 2 || (ARGV.one? && ARGV.first.to_i.to_s == ARGV.first)
		OPTIONS[:interactive] = true # this command forces interactive use
		year = Integer(ARGV.first, 10) # raises an exception if year is not integer
		season = ''
		unless ARGV.one?
			season = "&& season == #{ARGV.last}"
			# for checking and better error messages
			raise 'missing json, run malinder.sh first' unless File.exist?("#{CONFIG_DIR}sources/#{year}-#{ARGV.last}.json")
		end
		output_or_process(
			lambda{cache_query("year == #{year} #{season} && choice == -").map{|a| a['id']} },
			nil, nil
		)

	else
		puts 'unknown command, or wrong parameters.', '', HELP_TEXT
		exit 1
	end
end
