require 'csv'
require_relative 'malinder.rb'

prefix = 'https://myanimelist.net/anime/'
csv_options = {
	skip_blanks: true,
	# skip_lines: /^#/,
	col_sep: "\t",
	nil_value: '',
}

load_all_to_cache() # fills in CACHE

a,b = [
	CSV.read(ARGV[0], **csv_options),
	CSV.read(ARGV[1], **csv_options)
].map do |csv|
	csv.group_by{|a,b,c| b}.transform_values do |a|
		a.map{|a|"#{prefix}#{a[0]} - #{CACHE[a[0].to_i]&.fetch('title','-')}"}
	end
end


puts "want:", (a["want"] & b["want"])
puts "want/ok:", (a["okay"] & b["want"] + a["want"] & b["okay"])
puts "okay:", (a["okay"] & b["okay"])
puts "nope/want:", (a["nope"] & b["want"])
puts "want/nope:", (a["want"] & b["nope"])
