require_relative 'malinder.rb'
require 'csv'

if ARGV.include?('--help')
  puts 'give me files to merge and cleanup, the configured logfile is always input'
  puts 'inputs can be relative paths to the config directory'
  puts 'Tipp: write stdout somewhere else, only then override after checking the diff or so'
  puts '--json output json instead'
  puts '--help print this'
  exit 0
end

OUTPUT_JSON = ARGV.delete('--json')

CSV_OPTS = {
  col_sep: "\t",
  converters: :integer,
}
CSV_OPTS[:skip_lines] = /^(#|$)/ unless RUBY_VERSION.start_with?('2.')
def parse_csv(f)
  f = CACHE_DIR + f unless File.exists?(f) # allow relative paths
  header = File.new(f).readline
  if header.start_with?("id\t", "seencount(state)\t")
    STDERR.puts("reading with headers: #{f}")
    (CSV.read(f, **CSV_OPTS, headers: true).map do |r|
      h = r.to_h
      id = h.fetch('id')&.to_s&.split('/')&.last&.to_i
      id = h.fetch('id')&.to_s if h.fetch('id')&.to_s&.start_with?('imdb,')
      a = [
        id,
        h.fetch('year', nil),
        h.fetch('season', nil),
        h.fetch('state') do
          seencount, state = (h.fetch('seencount(state)').to_s.split('(').map{|x|x.chomp(')').split(',').first.strip} + ['partly']).first(2)
          seencount = Integer(seencount, 10)
          "#{state},#{seencount}".gsub('partly,0','want').gsub('plonk','broken')
        end,
        h.fetch('ts', 10),
        h.fetch('name',nil),
        h.fetch('c1',h.fetch(nil, nil)), h.fetch('c2',nil), h.fetch('c3',nil),
      ] rescue (raise "#{h}")
      a.reverse.drop_while(&:nil?).reverse
    end.compact)
  else
    STDERR.puts("reading: #{f}")
    CSV.read(f, **CSV_OPTS)
  end
end

load_all_to_cache()
csv = parse_csv(LOG_FILE_PATH)
ARGV.each{|f| csv += parse_csv(f)}
csv.map! do |r|
  if e = CACHE[r[0].to_i]
    s = e['start_season'].fetch_values('year','season') rescue []
    r[1] ||= s.first
    r[2] ||= s.last
    r[3] = "#{r[3]},#{e['num_episodes']}" if r[3] == 'seen'
    if ['', nil].include?(r[5])
      title_en = e.fetch('alternative_titles', {}).fetch('en')
      if ['', nil].include?(title_en)
        r[5] = e['title']
      else
        r[5] = title_en
      end
    end
  else
    STDERR.puts('ID Lookupfail: ' + r[0].to_s) unless r[0].nil? or r[0].to_s.start_with?('imdb,')
  end
  r
  # r.values_at(0,3,4,1,2,5)
end
csv

YEAR_SEASON = {'winter'=>1, 'spring'=>2, 'summer'=>3, 'fall'=>4}
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
csv.sort_by!{|e| x = e.values_at(1,2,0,4,5); x[1] = YEAR_SEASON[x[1]]; x.map(&:to_s).map(&:downcase)}
csv.uniq!
csv.compact.group_by(&:first).select{|k, v|v.size > 1}.each do |id, c|
  next if id == nil # ignore the nil group, you're on your own for now
  stages = c.group_by{|c|STATE_LEVEL.fetch(c[3].split(',').first)} rescue (raise c.inspect)
  seencount = c.group_by{|c|c[3].split(',').last.to_i}
  if c.count == 2 && (c.first == c.last[..5] || c.first[..5] == c.last)
    stays = c.max{|a,b| a.length <=> b.length}
      STDERR.puts('removing lines due to being same, except end: ' + (c - [stays]).inspect)
      STDERR.puts('stays: ' + stays.inspect)
    csv -= c - [stays]
  elsif c.reduce(true){|o,a| o && [a,c.first].map{|e|e.dup.tap{|x|x.delete_at(4)}}.inject(:==)}
    stays = c.min{|a,b| a[4] <=> b[4]}
    csv -= c - [stays]
    #STDERR.puts('removing: ' + (c - [stays]).inspect)
    #STDERR.puts('stays: ' + stays.inspect)
  elsif c.reduce(true){|o,a| o && a.values_at(0,3) == c.first.values_at(0,3)}
    if c.map{|a| a.values_at(*a.each_index.to_a - [1,2,4,5])}.uniq.one?
      stays = c.sort.first
      remainder = c - [stays]
      unless c.first == c.last
        STDERR.puts('removing lines due to same stuff: ' + remainder.inspect)
        STDERR.puts('stays: ' + stays.inspect)
      end
      csv -= remainder
    else
      STDERR.puts(c.inspect)
      raise 'all are same?'
    end
  elsif stages.count > 1 || seencount.count > 1
    #STDERR.puts(c.inspect)
    stays = seencount.max.last.group_by{|c|STATE_LEVEL.fetch(c[3].split(',').first)}.max.last
    STDERR.puts('removing lines due to more progressed stuff: ' + (c - stays).inspect)
    STDERR.puts('stays: ' + stays.inspect)
    csv -= c - stays
#  elsif c.map{|e| e[3]}.all?{|s| s.start_with?('broken')}
#    STDERR.puts(c.inspect)
#    raise 'all are broken'
  elsif c.map{|e| e[3]}.all?{|s| s.start_with?('partly')}
    STDERR.puts(c.inspect)
    raise "this should no longer be used"
    latest =  c.max{|a,b| a[3].split(',').last.to_i <=> b[3].split(',').last.to_i}
    remainder = c - [latest]
    STDERR.puts('removing lines due to newer: ' + remainder.inspect)
    STDERR.puts('stays: ' + latest.inspect)
    csv -= remainder
#  elsif c.map{|e| e[3]}.all?{|s| s.start_with?('seen')}
#    STDERR.puts(c.inspect)
#    raise 'all are seen'
  else
    STDERR.puts('couldn\'t merge:', c.inspect)
    raise 'couldn\'t merge'
    STDERR.puts("Duplicates: #{c.count} of #{id}")
  end
end
# raise 'stop hammertime' # to test the merging
unless OUTPUT_JSON
  out = "id\tyear\tseason\tstate\tts\tname\tc1\tc2\tc3\n"
  out += CSV.generate(col_sep: "\t"){|o| csv.each{|r| o << r}}
  puts out
else
  require 'json'
  configurable_default(:JSON_IGNORE, [])
  puts JSON.generate(csv.map do |r|
    next if JSON_IGNORE.include?(r[5])
    if e = CACHE[r[0].to_i]
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
    r
  end.compact)
end

if File.read(LOG_FILE_PATH) == out
  STDERR.puts('', 'files do not diff :)')
else
  STDERR.puts('', 'TOOL IS maybe still UnSaVE! diff the result to check or accept to loose some things!')
end
