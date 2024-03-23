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
configurable_default(:BAD_WORDS,
	%w(
		mini idol cultivat chibi promotion game pokemon sport mecha machine limited trailer short season
		special extra harem hentai ecchi kids collaboration commercial precure reborn rebirth revive isekai
		reincar sanrio compilation transformer
		youku bilibili
	)	+ ['love live', 'boys love', 'sailor moon', 'music film', 'music video']
)
configurable_default(:BAD_WORDS_REGEX, /\b#{ Regexp.union(BAD_WORDS).source }\b/i)
configurable_default(:DEFAULT_FILTER, '!(media_type == music || genres has hentai)') # set to nil to disable

# not configurable
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
IMAGE_CACHE = {}
LOG_FILE = File.open(LOG_FILE_PATH, 'a+')
LOG_FILE.sync = true
def parse_choices(file)
	file = CONFIG_DIR + file unless File.exists?(file)
	Hash[File.readlines(file).drop(1).map do |l|
		id, y, s, c, ts, name, c1, c2, c3 = l.split("\t")
		[id, {choice:c, ts: ts, c1: c1, c2: c2, c3: c3}]
	end]
end
CHOICES = parse_choices(LOG_FILE)
CHOICES_OTHERS = {}
(Dir["#{CONFIG_DIR}choices*.log"] - [LOG_FILE_PATH]).map do |path|
	name = path.delete_prefix(CONFIG_DIR + 'choices').delete_prefix('-').delete_suffix('.log')
	CHOICES_OTHERS[name] = parse_choices(path)
end
MAL_PREFIX = 'https://myanimelist.net/anime/'
MAL_MANGA_PREFIX = 'https://myanimelist.net/manga/'

def load_all_to_cache()
	require_relative '../../stdlib/array/query'
	Dir.chdir("#{CONFIG_DIR}sources/") do
		system('git', 'pull', '--ff-only', exception: true)
	end if AUTOPULL_SOURCES
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
			v['timestamp'] = old.fetch(:ts, date.to_i)
			v['c1'] = old.fetch(:c1, nil)
			v.merge!(v.fetch('start_season', {}))
			v['genres'] = v['genres']&.map{|h| (h.is_a?(Hash) ? h['name']: h).downcase.tr(' ', '_')}
			v['names'] = [v['title'], *v['alternative_titles']&.values.flatten]
			# v['names'] = [v['title'], *v.fetch('alternative_titles', {})&.values.flatten]

			CACHE_FULL[v['id']] ||= v
			# remove unwanted content
			next unless default_filter[v]
			CACHE[v['id']] ||= v
		end
	rescue JSON::ParserError => e
		raise "could not parse: #{s}"
	end
	# Ractor.make_shareable(CACHE)
end
def cache_query(query, all=false)
	(all ? CACHE_FULL : CACHE).values.query(query)
end

def compare(a,b)
	[a,b].map do |csv|
		csv.map{|k,v|[k,v]}.group_by{|k,h| h[:choice].split(',').first}
	end
end

def season_shortcuts(input)
	s = MALinder::SEASON_SHORTCUTS.fetch(input, input)
	raise "'#{input.inspect}' is not a season" unless MALinder::SEASON_SHORTCUTS.values.include?(s)
	s
end

def choices_path_to_prefix(path_or_filename)
	path_or_filename.rpartition('/').last.sub(/^choices-(.*).log$/, '\1')
end
