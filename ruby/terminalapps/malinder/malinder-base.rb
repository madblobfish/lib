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
require_optional(__dir__ + '/../../stdlib/duration'){
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

CONFIG_DIR = ENV.fetch('XDG_CONFIG_HOME', ENV.fetch('HOME') + '/.config') + '/malinder/'
require_optional(CONFIG_DIR + '/config.rb')

def configurable_default(name, default)
	Object.const_set(name, default) unless Object.const_defined?(name)
end
configurable_default(:API, 'https://api.myanimelist.net/v2/')
configurable_default(:AUTOPULL_SOURCES_WAIT, 86400*2)
sources_outdated = (Time.now - File.mtime("#{CONFIG_DIR}sources/.git/FETCH_HEAD")).to_f >= AUTOPULL_SOURCES_WAIT
configurable_default(:AUTOPULL_SOURCES, AUTOPULL_SOURCES_WAIT == 0 ? true : AUTOPULL_SOURCES_WAIT == -1 ? false : sources_outdated)
configurable_default(:AUTOPULL_CONFIG_WAIT, 86400)
config_outdated = (Time.now - File.mtime("#{CONFIG_DIR}.git/FETCH_HEAD")).to_f >= AUTOPULL_CONFIG_WAIT
configurable_default(:AUTOPULL_CONFIG, AUTOPULL_CONFIG_WAIT == 0 ? true : AUTOPULL_CONFIG_WAIT == -1 ? false : sources_outdated)
configurable_default(:CACHE_DIR, ENV.fetch('XDG_CACHE_HOME', ENV.fetch('HOME') + '/.cache') + '/malinder/')
CACHE_DIR_IMAGES = CACHE_DIR + 'images/'
CACHE_DIR_RELATIONS = CACHE_DIR + 'relations/'
FileUtils.mkdir_p(CACHE_DIR_IMAGES)
FileUtils.mkdir_p(CACHE_DIR_RELATIONS)
configurable_default(:DEFAULT_HEADERS, {}) # currently unused
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
configurable_default(:DEFAULT_FILTER, '!(media_type == music || genres has hentai || names like rainbow)') # set to nil to disable

# not configurable
CACHE = {}
CACHE_BY_RANK = {}
IMAGE_CACHE = {}
LOG_FILE = File.open(LOG_FILE_PATH, 'a+')
LOG_FILE.sync = true
def parse_choices(file)
	Hash[file.each_line.drop(1).map do |l|
		id, y, s, c, ts, name, c1, c2, c3 = l.split("\t")
		[id, {choice:c, ts: ts, c1: c1, c2: c2, c3: c3}]
	end]
end
CHOICES = parse_choices(LOG_FILE)
CHOICES_OTHERS = {}
(Dir["#{CONFIG_DIR}choices*.log"] - [LOG_FILE_PATH]).map do |path|
	name = path.delete_prefix(CONFIG_DIR + 'choices').delete_prefix('-').delete_suffix('.log')
	CHOICES_OTHERS[name] = parse_choices(File.open(path))
end
MAL_PREFIX = 'https://myanimelist.net/anime/'
MAL_MANGA_PREFIX = 'https://myanimelist.net/manga/'

def load_all_to_cache()
	require_relative '../../stdlib/array/query'
	system({'GIT_DIR'=> "#{CONFIG_DIR}sources/.git"}, 'git', 'fetch', exception: true) if AUTOPULL_SOURCES
	default_filter = DEFAULT_FILTER.nil? ? lambda{|_|true} : Array::QueryParser.new.parse(DEFAULT_FILTER)
	date = Time.now
	Dir[CONFIG_DIR + 'sources/*'].map do |s|
		JSON.parse(File.read(s))['data'].each do |blah|
			# unified cache internal representation
			v = blah['node']
			old = CHOICES.fetch(v['id'].to_s, {})
			v['state'] = old.fetch(:choice, '-')
			v['choice'] = v['state'].split(',').first
			CHOICES_OTHERS.each do |name, c|
				choice = c.fetch(v['id'].to_s, {}).fetch(:choice, '-')
				v['state-' + name] = choice
				v['choice-' + name] = choice.split(',').first
			end
			v['timestamp'] = old.fetch(:ts, date)
			v['c1'] = old.fetch(:c1, nil)
			v.merge!(v['start_season'])
			v['genres'] = v['genres']&.map{|h| h['name'].downcase.tr(' ', '_')}
			v['names'] = [v['title'], *v['alternative_titles']&.values.flatten]
			# v['names'] = [v['title'], *v.fetch('alternative_titles', {})&.values.flatten]

			# remove unwanted content
			next unless default_filter[v]
			CACHE[v['id']] ||= v
			CACHE_BY_RANK[v['rank']] ||= v['id']
		end
	end
	# Ractor.make_shareable(CACHE)
end
def cache_query(query)
	load_all_to_cache()
	CACHE.values.query(query)
end

def compare(a,b)
	[a,b].map do |csv|
		csv.group_by{|_,_,_,d| d.split(',').first}
	end
end

def season_shortcuts(input)
	s = MALinder::SEASON_SHORTCUTS.fetch(input, input)
	raise "'#{input.inspect}' is not a season" unless MALinder::SEASON_SHORTCUTS.values.include?(s)
	s
end