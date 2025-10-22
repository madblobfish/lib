require_relative 'malinder-base.rb'
require 'csv'

if ARGV.include?('--help')
  puts 'give me files to merge and cleanup, the configured logfile is always input'
  puts 'inputs can be relative paths to the config directory'
  puts '--nocurrent do not load the configured logfile'
  puts '--gitmerge integration as git custom merge driver: see readme!'
  puts '--json output json instead'
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
if GITMERGE
  raise "nope" unless NOCURRENT
  raise "nope" unless INPLACE
  input = IO.popen(['git', 'merge-file', '--', ARGV[0], ARGV[1], ARGV[2]]).read
  raise 'error in git-merge-file' if input.nil? && $? >= 128
  ARGV.pop; ARGV.pop # get rid of trailing files
  raise 'aahh' unless ARGV.one? # sanity check of above
end

lock_logfile()
load_all_to_cache()
csv = []
csv = read_choices(LOG_FILE_PATH) unless NOCURRENT
ARGV.each{|f| csv += read_choices(f)}
csv.map! do |entry|
  r = entry.fetch_values(*%w(id year season state ts name c1 c2 c3))
  unless CACHE_FULL[entry['id'].to_i] || DELETIONS[entry['id'].to_s]
    STDERR.puts('ID Lookupfail: ' + r[0].to_s) unless r[0].nil? or r[0].to_s.start_with?('imdb,')
  end
  r
  # r.values_at(0,3,4,1,2,5)
end
csv

YEAR_SEASON = {'winter'=>1, 'spring'=>2, 'summer'=>3, 'fall'=>4}

csv.uniq!
csv.sort_by!{|e| x = e.values_at(1,2,0,4,5); x[1] = YEAR_SEASON[x[1]]; x.map(&:to_s).map(&:downcase)}
csv.compact.group_by(&:first).select{|k, v|v.size > 1}.each do |id, c|
  next if id == nil # ignore the nil group, you're on your own for now
  stages = c.group_by{|c|STATE_LEVEL.fetch(c[3].split(',').first)} rescue (raise c.inspect)
  seencount = c.group_by{|c|c[3].split(',').last.to_f}
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
    if c.map{|a| a.values_at(*a.each_index.to_a - [1,2])}.uniq.one?
      not_empty = c.reject{|a| a.values_at(1,2).compact.empty?}
      if not_empty.group_by{|a| a.values_at(1,2)}.one?
        remainder = c - [not_empty.first]
        # STDERR.puts('removing lines due to missing season information: ' + remainder.inspect)
        # STDERR.puts('stays: ' + not_empty.first.inspect)
        csv -= remainder
      else
        raise "new case #{c}"
      end
    elsif c.map{|a| a.values_at(*a.each_index.to_a - [1,2,4,5])}.uniq.one?
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
    STDERR.puts('removing lines due to more progressed stuff: ' + (c - stays).inspect) if VERBOSE
    STDERR.puts('stays: ' + stays.inspect) if VERBOSE
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
  out += CSV.generate(col_sep: "\t"){|o| csv.each{|r| o << r.reverse.drop_while(&:nil?).reverse}}
  if File.read(LOG_FILE_PATH) == out
    STDERR.puts('', 'files do not diff :)')
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
  body = csv.map do |r|
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
