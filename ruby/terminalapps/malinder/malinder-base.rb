require 'csv'
require 'fileutils'
require 'json'
require 'net/http'
require 'set'
require 'socket'

OFFLINE =
	begin
		if ENV['OFFLINE']
			true
		else
			Socket.tcp("1.1.1.1", 53, connect_timeout: 0.5){}
			false
		end
	rescue Errno::ENETUNREACH, Errno::ETIMEDOUT
		true
	rescue
		false
	end

def fetch(url, **stuff)
	raise "offline" if OFFLINE
	headers = stuff.fetch(:headers, {})
	content = stuff[:content]

	uri = URI.parse(url)
	ret = Net::HTTP.start(uri.hostname, uri.port, use_ssl: stuff.fetch(:use_ssl, uri.scheme == 'https'), open_timeout: 3) do |http|
		verb = stuff[:verb] || content.nil? ? 'GET' : 'POST'
		http.send_request(verb, uri, content, headers)
	end
	raise "#{ret.code} - #{url}" if ret.code != '200'
	return ret
end
def is_offline?()
	fetch('https://fefe.de')
	false
rescue
	true
end

def require_optional(name)
	require name
	true
rescue LoadError
	yield if block_given?
	false
end
VIPS = require_optional('vips')
require_optional(__dir__ + '/../../stdlib/duration'){
	class Duration
		def self.parse;self.new(0);end
		def initialize(secs)
			@secs = secs
			@secs
		end
		def to_s;@secs.to_s;end
		def to_i;@secs;end
	end
}

CONFIG_DIR = ENV.fetch('XDG_CONFIG_HOME', ENV.fetch('HOME') + '/.config') + '/malinder/'
require_optional(CONFIG_DIR + '/config.rb')

def configurable_default(name, default)
	Object.const_set(name, default) unless Object.const_defined?(name)
end
configurable_default(:API, 'https://api.myanimelist.net/v2/')
configurable_default(:AUTOPULL_SOURCES_WAIT, 86400*2)
sources_outdated = (Time.now - File.mtime("#{CONFIG_DIR}sources/.git/FETCH_HEAD")).to_f >= AUTOPULL_SOURCES_WAIT rescue true
configurable_default(:AUTOPULL_SOURCES, AUTOPULL_SOURCES_WAIT == 0 ? true : AUTOPULL_SOURCES_WAIT == -1 ? false : sources_outdated)
configurable_default(:AUTOPULL_CONFIG_WAIT, 86400)
config_outdated = (Time.now - File.mtime("#{CONFIG_DIR}.git/FETCH_HEAD")).to_f >= AUTOPULL_CONFIG_WAIT rescue true
configurable_default(:AUTOPULL_CONFIG, AUTOPULL_CONFIG_WAIT == 0 ? true : AUTOPULL_CONFIG_WAIT == -1 ? false : sources_outdated)
configurable_default(:CACHE_DIR, ENV.fetch('XDG_CACHE_HOME', ENV.fetch('HOME') + '/.cache') + '/malinder/')
CACHE_DIR_IMAGES = CACHE_DIR + 'images/'
CACHE_DIR_RELATIONS = CACHE_DIR + 'relations/'
FileUtils.mkdir_p(CACHE_DIR_IMAGES)
FileUtils.mkdir_p(CACHE_DIR_RELATIONS)
configurable_default(:DEFAULT_HEADERS, {}) # currently unused
configurable_default(:LOG_SUFFIX, '-' + ENV['USER'])
LOG_FILE_NAME = "choices#{LOG_SUFFIX}.log"
configurable_default(:LOG_FILE_PATH, "#{CONFIG_DIR}#{LOG_FILE_NAME}")
configurable_default(:FAV_FILE_PATH, "#{CONFIG_DIR}favorites#{LOG_SUFFIX}.txt")
configurable_default(:DELETIONS_PATH, "#{CONFIG_DIR}sources/deletions.txt")
configurable_default(:OFFSETS_PATH, "#{CONFIG_DIR}sources/offsets.txt")
configurable_default(:BAD_WORDS,
	%w(
		mini idol cultivat chibi promotion game pokemon pokémon sport mecha machine transformer
		special extra harem hentai ecchi kids collaboration commercial precure reborn rebirth revive isekai
		reincar sanrio compilation limited trailer short season recap sect sponsor promote
		youku bilibili summary strongest invincible
	)	+ [
		'love live', 'boys love', 'sailor moon', 'music film', 'music video', 'variety program',
		'martial art'
	]
)
configurable_default(:BAD_WORDS_REGEX, /\b#{ Regexp.union(BAD_WORDS).source }\b/i)
configurable_default(:DEFAULT_FILTER, '!(media_type in music,cm,pv || genres in hentai,erotica) && !(num_episodes == 1 && average_episode_duration <= 1000) && (average_episode_duration >= 300 || average_episode_duration == 0)') # set to nil to disable

# not configurable
MALINDER_FILE_PREFIX_REGEX = /^\d+-S\d+E\d+-/
SEASON_SHORTCUTS = {
	'w'=> 'winter', 'sp'=> 'spring', 'su'=> 'summer', 'f'=> 'fall',
	'1'=> 'winter', '2'=> 'spring', '3'=> 'summer', '4'=> 'fall',
}
STATE_LEVEL = {
	# initial
	'want'=> 0, 'nope'=> 0, 'okay'=> 0,
	# intermediate
	'backlog'=> 1,
	# progress
	'partly'=> 2,
	# stopped
	'paused'=> 3,
	'broken'=> 4, #'plonk'=> 4,
	# done
	'seen'=> 5,
}
STATE_ACTIVE = %w(partly paused broken)
STATE_INACTIVE = STATE_LEVEL.keys - STATE_ACTIVE
CACHE = {}
CACHE_FULL = {}
if File.readable?(FAV_FILE_PATH)
	FAVORITES = Hash[File.readlines(FAV_FILE_PATH, chomp: true).map{|l| l.split("\t", 3)[0..1] }]
else
	FAVORITES = {}
end
DELETIONS = Hash[(File.readlines(DELETIONS_PATH, chomp: true) rescue []).map{|l| [l, true] }]
OFFSETS = Hash[(File.readlines(OFFSETS_PATH, chomp: true) rescue []).map{|l| l.split("\t") }]
IMAGE_CACHE = {}
LOG_FILE = File.open(LOG_FILE_PATH, 'a+')
LOG_FILE.sync = true

CSV_OPTS = {
	col_sep: "\t",
}
CSV_OPTS[:skip_lines] = /^(#|$|<<+|==+|>>+|\|\|+)/
def read_choices(file)
	file = CONFIG_DIR + file if File.exist?(CONFIG_DIR + file) # allow relative paths
	headers = %w(id year season state ts name c1 c2 c3)
	headers = true if File.read(file, 20).start_with?("id\t", "seencount(state)\t")
	CSV.read(file, **CSV_OPTS, headers: headers).map do |r|
		r = r.to_h.reject{|k,v| v.nil?}
		r['id'] = r['id'].rpartition('/').last.to_i.to_s if r['id'].start_with?('https://')
		id = Integer(r['id'], 10) rescue r['id']
		cached_entry = CACHE_FULL.fetch(id, {})
		r['ts'] = r.fetch('ts', 10).to_i
		r['name'] = r.fetch('name', nil)
		r['c1'] = r.fetch('c1', r.fetch(nil, nil))
		r['c2'] = r.fetch('c2', nil)
		r['c3'] = r.fetch('c3', nil)
		r['year'] = r.fetch('year', cached_entry.fetch('year', nil))
		r['year'] = Integer(r['year'], 10) rescue r['year']
		r['season'] = r.fetch('season', cached_entry.fetch('season', nil))
		r['state']&.chomp!(',')
		r['state'] = r.fetch('state') do
			seencount, state = (r.fetch('seencount(state)').to_s.split('(').map{|x|x.chomp(')').split(',').first.strip} + ['partly']).first(2)
			seencount = Integer(seencount.sub(/\[[^\]]+\]/, '').sub(/\.(\d+)$/, ''), 10)
			seencount_fac = $1 ? ".#{Integer($1)}" : ''
			"#{state},#{seencount}#{seencount_fac}".gsub('partly,0','want').gsub('plonk','broken')
		end
		if r['state'] == 'seen' && cached_entry&.any? && cached_entry['num_episodes'] != 0
			r['state'] += ",#{cached_entry['num_episodes']}"
		end
		if ['', nil].include?(r['name'])
		  title_en = cached_entry.fetch('alternative_titles', {})['en']
		  if ['', nil].include?(title_en)
				r['name'] = cached_entry['title']
		  else
				r['name'] = title_en
		  end
		end
		r.delete('choice')
		r
	end.compact
end
def parse_choices(file)
	out = {}
	read_choices(file).each_with_index do |c, i|
		raise 'duplicate entry, run db-pfusch, row: ' + i if out[c[0]]
		out[c['id']] = c
	end
	return out
end

def choices_path_to_prefix(path_or_filename)
	path_or_filename.rpartition('/').last.sub(/^choices-(.*).log$/, '\1')
end

CHOICES = parse_choices(LOG_FILE_PATH)
CHOICES_OTHERS = {}
(Dir["#{CONFIG_DIR}choices*.log"] - [LOG_FILE_PATH]).map do |path|
	CHOICES_OTHERS[choices_path_to_prefix(path)] = parse_choices(path)
end
MAL_PREFIX = 'https://myanimelist.net/anime/'
MAL_MANGA_PREFIX = 'https://myanimelist.net/manga/'

IDS_IN_RELATED_CACHE = Dir.children(CACHE_DIR_RELATIONS).map{|s|s.rpartition('.').first.to_i}.to_set
IDS_IN_IMAGE_CACHE = Dir.children(CACHE_DIR_IMAGES).map{|s|s.rpartition('.').first.to_i}.to_set
IDS_IN_CACHE = IDS_IN_RELATED_CACHE & IDS_IN_IMAGE_CACHE
def anime_files_in_cache?(id)
	IDS_IN_CACHE.include?(id.to_i)
end

def load_all_to_cache()
	require_relative '../../stdlib/array/query'
	Dir.chdir("#{CONFIG_DIR}sources/") do
		system('git', 'pull', '--ff-only', exception: true) unless is_offline?
	end if AUTOPULL_SOURCES
	default_filter = DEFAULT_FILTER.nil? ? lambda{|_|true} : Array::QueryParser.new.parse(DEFAULT_FILTER)
	date = Time.now
	Dir[CONFIG_DIR + 'sources/*.json'].map do |s|
		JSON.parse(File.read(s))['data'].each do |blah|
			# unified cache internal representation
			v = blah['node']
			old = CHOICES.fetch(v['id'].to_s, {})
			v['state'] = old.fetch('state', '-')
			v['choice'] = v['state'].split(',', 2).first
			v['choices_related'] = fetch_related(v['id']).flat_map{|rel| rel['entry'].select{|r| r['type'] == 'anime'}.map{|r| CHOICES.fetch(r['mal_id'].to_s, {}).fetch('state', '-')}} rescue ['ratelimited']
			CHOICES_OTHERS.each do |name, c|
				choice = c.fetch(v['id'].to_s, {}).fetch('state', '-')
				v['state-' + name] = choice
				v['choice-' + name] = choice.split(',', 2).first
			end
			v['timestamp'] = old.fetch('ts', date.to_i)
			v['c1'] = old.fetch('c1', nil)
			v.merge!(v.fetch('start_season', {}))
			v['genres'] = v['genres']&.map{|h| (h.is_a?(Hash) ? h['name']: h).downcase.tr(' ', '_')}
			v['names'] = [v['title'], *v['alternative_titles']&.values.flatten].reject{|n| n == ''}
			v['incache'] = anime_files_in_cache?(v['id'])
			if FAVORITES.has_key?(v['id'].to_s)
				v['symbols'] = FAVORITES[v['id'].to_s]
			end
			# v['names'] = [v['title'], *v.fetch('alternative_titles', {})&.values.flatten]

			CACHE_FULL[v['id']] ||= v
			# remove unwanted content
			next unless default_filter[v]
			CACHE[v['id']] ||= v
		end
	rescue
		raise "could not parse: #{s}"
	end
	# Ractor.make_shareable(CACHE)
end
def cache_query(query, all=false)
	(all ? CACHE_FULL : CACHE).values.query(query)
end

def compare(a,b)
	[a,b].map do |csv|
		csv.map{|k,v|[k,v]}.group_by{|k,h| h['state']&.split(',')&.first}
	end
end

def season_shortcuts(input)
	s = SEASON_SHORTCUTS.fetch(input, input)
	raise "'#{input.inspect}' is not a season" unless SEASON_SHORTCUTS.values.include?(s)
	s
end

def fetch_related(id, sleeps=false)
	return [] if id.to_s.start_with?('imdb,')
	return [] if id.to_i == 0
	cached_file = CACHE_DIR_RELATIONS + id.to_i.to_s + '.json'
	if File.exist?(cached_file)
		related = File.read(cached_file)
	else
		# backoff a bit to not run into ratelimits
		age = Time.now - File.mtime("#{CACHE_DIR_RELATIONS}")
		if sleeps
			sleep(1 - [age.to_f, 0].max + 0.1) if age.to_f <= 1
		elsif age.to_f <= 1
			return 'Ratelimited - internally'
		end
		related = fetch("https://api.jikan.moe/v4/anime/#{id.to_i}/relations").body
		File.write(cached_file, related)
	end
	JSON.parse(related).fetch('data').map{|e| e["entries"] = e["entry"]; e}.select{|e| e["entries"]&.any?}
rescue SocketError => e
	raise unless e.message.include?('(getaddrinfo: ')
	'No internet, lol'
rescue RuntimeError => e
	raise unless e.message.start_with?('429 - ') or e.message == 'offline'
	'Ratelimited - got Error 429'
end
# fetch(API + 'anime/30230')
# fetch(j['main_picture']['large'])

def image(anime, nofetch=false)
	id = anime['id']
	return IMAGE_CACHE[id] if IMAGE_CACHE.has_key?(id)
	path = "#{CACHE_DIR_IMAGES}#{id.to_i}.png"
	if File.exist?(path)
		(return IMAGE_CACHE[id] = Vips::Image.new_from_file(path)) rescue nil
	end
	return %w(medium large).any?{|k| anime.fetch('main_picture', {}).has_key?(k)} if nofetch
	return IMAGE_CACHE[id] = Vips::Image.text("No Image\n:(") unless anime['main_picture']
	begin
		image = fetch(anime['main_picture'].fetch('large', anime['main_picture']['medium'])).body
		File.write(path, image)
		IMAGE_CACHE[id] = Vips::Image.new_from_buffer(image, '')
	rescue
		raise "Could not load image for: #{id}"
	end
end

def prefetch(list)
	puts "prefetching #{list.count} animes... this can take up to #{Duration.new(list.count)}"
	list.each do |a|
		a = CACHE_FULL[a] if a.is_a?(Integer)
		fetch_related(a['id'], true)
		image(a)
	end
end

def parse_local_files(filter, path='')
	files = Hash[Dir[path + '[0-9]*-*.{mkv,mp4}']
		.map{|f| [f.split('-',2).first.to_i, f]}
		.compact.group_by(&:first).transform_values{|l|l.map(&:last)}
		.map do |id, l|
			seen, seen_time = CHOICES[id.to_s]['state'].split(',', 2)[1].split(',', 2) rescue ['0', nil]
			seen = Integer(seen, 10)
			seen -= 1 if seen_time
			[id, l.map do |f|
				ep = f.split('-',3)[1].split('E',2).last.to_i
				if filter[seen, ep, id]
					[f, ep]
				else
					nil
				end
			end.compact]
		end]
end

def episode_wrap(id, ep)
	ep = ep.to_i
	offset = OFFSETS[id.to_s].to_i
	return ep unless offset > 0
	if ep >= offset
		ep -= offset - 1
	end
	return ep
end
