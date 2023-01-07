require 'csv'
require_relative 'malinder.rb'

def compare(a,b)
	prefix = 'https://myanimelist.net/anime/'
	load_all_to_cache() # fills in CACHE
	[a,b].map do |csv|
		csv.select{|x| x.values_at(1,2) == %w(2023 winter)}.group_by{|_,_,_,d| d.split(',').first}.transform_values do |a|
			a.map{|a|"0\t#{a[0]}\t#{CACHE[a[0].to_i]&.fetch('title','-')}\t#{prefix}#{a[0]}"}
		end
	end
end

if __FILE__ == $PROGRAM_NAME
	if ARGV.empty?
		puts 'give me two files to compare,'
		puts '  or one if you got your own.'
		exit
	end

	own = ARGV.first
	own = LOG_FILE_PATH if ARGV.length == 1
	other = ARGV.last

	csv_options = {
		skip_blanks: true,
		# skip_lines: /^#/,
		col_sep: "\t",
		nil_value: '',
	}
	a,b = compare(
		CSV.read(own, **csv_options),
		CSV.read(other, **csv_options)
	)

	puts "want:", (a["want"] & b["want"])
	puts "want/ok:", (a["okay"] & b["want"] + a["want"] & b["okay"])
	puts "okay:", (a["okay"] & b["okay"])
	puts "nope/want:", (a["nope"] & b["want"])
	puts "want/nope:", (a["want"] & b["nope"])
end
