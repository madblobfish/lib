require_relative 'malinder.rb'
require 'csv'

json = ARGV.delete('--json')

CSV_OPTS = {
  col_sep: "\t",
  converters: :integer,
}
time_watched_sum = 0
time_sum = 0
csv = CSV.read(LOG_FILE_PATH, **CSV_OPTS)
load_all_to_cache()
ARGV.each{|f| csv += CSV.read(f, **CSV_OPTS)}
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
    status, seen_eps = r[3].split(',', 2)
    seen_eps ||= e['num_episodes'] if status == 'seen'
    if %w(paused partly broken seen).include?(status)
      time_watched_sum += seen_eps.to_i * e.fetch('average_episode_duration', 0)
    end
    unless %w(nope okay).include?(status)
      eps = e['num_episodes']
      eps = seen_eps || eps if status == 'broken'
      time_sum += eps.to_i * e.fetch('average_episode_duration', 0)
    end
  else
    STDERR.puts('ID Lookupfail: ' + r[0].to_s) unless r[0].nil?
  end
  r
  # r.values_at(0,3,4,1,2,5)
end

YEAR_SEASON = {'winter'=>1, 'spring'=>2, 'summer'=>3, 'fall'=>4}
csv.sort_by!{|e| x = e.values_at(1,2,0,4,5); x[1] = YEAR_SEASON[x[1]]; x.map(&:to_s).map(&:downcase)}
csv.uniq!
csv.compact.group_by(&:first).select{|k, v|v.size > 1}.each do |id, c|
  next if id == nil # ignore the nil group, you're on your own for now
  c_stage_one = c.select{|c|c[3].start_with?(*%w(want nope okay))}
  c_backlog = c.select{|c|c[3].start_with?(*%w(backlog))}
  c_progress = c.select{|c|c[3].start_with?(*%w(partly paused))}
  c_done = c.select{|c|c[3].start_with?(*%w(seen broken))}
  if c.count == 2 && (c.first == c.last[..5] || c.first[..5] == c.last)
    stays = c.max{|a,b| a.length <=> b.length}
    STDERR.puts('removing lines due to being same, except end: ' + (c - stays).inspect)
    STDERR.puts('stays: ' + stays.inspect)
    csv -= c - stays
  elsif c.reduce(true){|o,a| o && a.values_at(0,3) == c.first.values_at(0,3)}
    if c.map{|a| a.values_at(*a.each_index.to_a - [1,2,4,5])}.uniq.one?
      stays = c.sort.first
      remainder = c - [stays]
      STDERR.puts('removing lines due to same stuff: ' + remainder.inspect)
      STDERR.puts('stays: ' + stays.inspect)
      csv -= remainder
    else
      p c
      raise 'all are same?'
    end
  elsif [c_stage_one,c_backlog,c_progress,c_done].map(&:any?).count(true) > 1
    stays = if c_done.any?
        c_done
      elsif c_progress.any?
        c_progress
      elsif c_backlog.any?
        c_backlog
      end
    STDERR.puts('removing lines due to more progressed stuff: ' + (c - stays).inspect)
    STDERR.puts('stays: ' + stays.inspect)
    csv -= c - stays
  elsif c.map{|e| e[3]}.all?{|s| s.start_with?('broken')}
    p c
    raise 'all are broken'
  elsif c.map{|e| e[3]}.all?{|s| s.start_with?('partly')}
    latest =  c.max{|a,b| a[3].split(',').last.to_i <=> b[3].split(',').last.to_i}
    remainder = c - [latest]
    STDERR.puts('removing lines due to newer: ' + remainder.inspect)
    STDERR.puts('stays: ' + latest.inspect)
    csv -= remainder
  elsif c.map{|e| e[3]}.all?{|s| s.start_with?('seen')}
    p c
    raise 'all are seen'
  else
    next if [41611, ].include?(id)
    p c
    raise 'couldn\'t merge'
    STDERR.puts("Duplicates: #{c.count} of #{id}")
  end
end
# raise 'stop hammertime' # to test the merging
unless json
  puts CSV.generate(col_sep: "\t"){|o| csv.each{|r| o << r}}
else
  require 'json'
  puts JSON.generate(csv.map do |r|
    if ['Rick and Morty', 'Immoral Guild', 'KissXsis'].include?(r[5])
      next
    end
    if e = CACHE[r[0].to_i]
      r[6] = e['num_episodes']
      r[7] = e['average_episode_duration']
      r[8] = e['rank']
      r[9] = e['mean']
      r[10] = e['popularity']
    else
      r[6] = nil
      r[7] = nil
    end
    r
  end.compact)
end
STDERR.puts '', 'Statistics:'
csv.map{|r|r[3].split(',').first}.group_by{|e|e}.map{|a,b|[a,b.count]}.map{|e| STDERR.puts e.to_s }
STDERR.puts '', 'Time spent (in secs):', time_watched_sum
STDERR.puts '', 'Time to go: ', time_sum
seen_amount = csv.map(&:first).uniq.size
STDERR.puts('Ratio: %2.2f%% (%d of %d)' % [seen_amount*100.0/CACHE.size, seen_amount, CACHE.size])
