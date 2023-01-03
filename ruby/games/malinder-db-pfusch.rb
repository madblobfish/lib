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
ARGV.each{|p| csv += CSV.read(p, **CSV_OPTS)}
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
csv.map(&:first).compact.group_by{|e|e}.select{|k, v|v.size > 1}.each do |id, c|
  STDERR.puts("Duplicates: #{c.count} of #{id}")
end
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
