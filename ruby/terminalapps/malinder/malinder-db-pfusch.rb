require_relative 'malinder-base.rb'

if ARGV.include?('--help')
  puts 'give me files to merge and cleanup, the configured logfile is always input'
  puts 'inputs can be relative paths to the config directory'
  puts '--nocurrent do not load the configured logfile'
  puts '--gitmerge integration as git custom merge driver: see readme!'
  puts '--json output json instead'
  puts '--all output contains nopes'
  puts '--inplace override the choices file, only for non json'
  puts '-v be more loud'
  puts '--help print this'
  exit 0
end

OUTPUT_JSON = ARGV.delete('--json')
INPLACE = ARGV.delete('--inplace')
VERBOSE = ARGV.delete('-v')
NOCURRENT = ARGV.delete('--nocurrent')
GITMERGE = ARGV.delete('--gitmerge')
ALL = ARGV.delete('--all')

if GITMERGE
  raise "nope" unless NOCURRENT
  raise "nope" unless INPLACE
  input = IO.popen(['git', 'merge-file', '--', ARGV[0], ARGV[1], ARGV[2]]).read
  raise 'error in git-merge-file' if input.nil? && $? >= 128
  ARGV.pop; ARGV.pop # get rid of trailing files
  raise 'aahh' unless ARGV.one? # sanity check of above
end

load_all_to_cache()
lock_logfile()
merged = {}
csv = []
csv = read_choices(LOG_FILE_PATH) unless NOCURRENT
ARGV.each{|f| csv += read_choices(f)}
state_split = lambda{|x| x['state'].split(',', 2)}
csv.each do |entry|
  if entry['id'].nil?
    STDERR.puts('ID missing! throwing away for now, sorry')
    next
  end
  id = entry['id'].to_s
  unless CACHE_FULL[id.to_i] || DELETIONS[id]
    STDERR.puts('ID Lookupfail: ' + id) unless entry['id'].nil? or id.start_with?('imdb,')
  end
  unless merged.has_key?(id)
    merged[id] = entry
    next
  end
  entry['ts'] = merged[id]['ts'] = [entry['ts'], merged[id]['ts']].min
  entry['c1'] = merged[id]['c1'] if entry['c1'].nil?
  entry['c2'] = merged[id]['c2'] if entry['c2'].nil?
  entry['c3'] = merged[id]['c3'] if entry['c3'].nil?
  cmp_state_level = [merged[id], entry].max(2){|a,b| STATE_LEVEL[state_split[a].first] <=> STATE_LEVEL[state_split[b].first]}
  cmp_watch_state = [merged[id], entry].max(2){|a,b| state_split[a].last <=> state_split[b].last}
  if cmp_state_level.one?
    if cmp_watch_state.one? && cmp_state_level != cmp_watch_state
      state = state_split[cmp_state_level.first].first
      cmp_state_level.first['state'] = state + ',' + state_split[cmp_watch_state.first].last
    end
    merged[id] = cmp_state_level.first
    next
  end
  if cmp_watch_state.one?
    merged[id] = cmp_watch_state.first
    next
  end
  merged[id] = entry # use last processed line as truth!
end

YEAR_SEASON = {'winter'=>1, 'spring'=>2, 'summer'=>3, 'fall'=>4}
output = merged.map{|k,v| v.values_at(*%w(id year season state ts name c1 c2 c3)) }
  .sort_by{|e| x = e.values_at(1,2,0,4,5); x[1] = YEAR_SEASON[x[1]]; x.map(&:to_s).map(&:downcase)}

unless OUTPUT_JSON
  out = "id\tyear\tseason\tstate\tts\tname\tc1\tc2\tc3\n"
  out += CSV.generate(col_sep: "\t"){|o| output.each{|r| o << r.reverse.drop_while(&:nil?).reverse}}
  if File.read(LOG_FILE_PATH) == out
    STDERR.puts('', 'files do not diff')
  else
    STDERR.puts('', 'this tool is maybe still unsave diff the result to check or accept to loose some things!')
  end
  if INPLACE
    File.write(NOCURRENT ? ARGV.first : LOG_FILE_PATH, out)
  else
    puts out
  end
else
  require 'json'
  configurable_default(:JSON_IGNORE, [])
  headers = %w(id year season state ts name favorite num_episodes average_episode_duration rank mean title_en title_ja)
  body = output.map do |r|
    next if !ALL && r[3] == 'nope'
    next if JSON_IGNORE.include?(r[5])
    next if JSON_IGNORE.include?(r[0].to_s)
    if e = CACHE_FULL[r[0].to_i]
      r[6] = e['num_episodes']
      r[7] = e['average_episode_duration']
      r[8] = e['rank']
      r[9] = e['mean']
      r[10] = e['popularity']
      r[11] = e['alternative_titles']['en']
      r[12] = e['alternative_titles']['ja']
    else
      r[6] = nil
      r[7] = nil
    end
    r.reverse.drop_while(&:nil?).reverse
  end.compact

  puts JSON.generate({
    head: headers,
    anime: body,
    symbols: FAVORITES
  })
end
