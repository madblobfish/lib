# download db from https://maclookup.app/downloads/csv-database
require 'csv'
raise 'gimme a mac or macprefix' unless ARGV.one?
puts CSV.read(File.dirname(__FILE__) + '/.mac-vendors-export.csv', headers: true).find{|r| ARGV.first.upcase.start_with?(r["Mac Prefix"])}.to_h.map{|k,v|"#{k}: #{v}"}
