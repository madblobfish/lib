# this simple tool uses openssl and checks for server side reduction of PFS.
# currently it checks for a long session ticket lifetime hint
# and checks if the hint is true
#
# Also makes multiple connections tying to find out
# if the first 16 bytes of the session ticket reoccur
#
# This tool is inspired by http://dx.doi.org/10.1145/2987443.2987480.
# Lets take a moment to shame apache, because they provide bad defaults:
#   https://httpd.apache.org/docs/trunk/mod/mod_ssl.html#SSLSessionTickets
# Lets take a moment to shame nginx, because they provide bad defaults:
#   https://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_session_tickets
# also HAProxy and many others. All thanks to OpenSSL yay

# todo:
# check for SSL terminators: which can share cryptographic state between domains
# DHE: check for reuse of a, g_a
# ECDHE: check for reuse of d_A, d_A * G
# accepting Session ID for a long time

require 'optsparser_generator'
require 'open3'
require 'tempfile'
require 'date'
require_relative 'stdlib/array/count_unique.rb' # could be included here too

# conf
opts = OpenStruct.new
opts.port = 443
opts.port__short = 'p'
opts.host = 'localhost'
opts.cmd = %w(openssl s_client -showcerts -connect)
opts.first_check_tries = 6
opts.first_check_tries__short = 'r'
opts.lifetimehint_too_long = 60 * 60 * 24 * 30
opts.test_lifetime = true
opts.test_lifetime_retries = 3
opts.test_lifetime_tolerance = 10
opts.time_format = '%Y-%m-%d %H:%M:%S'
opts.storage_file = 'results.csv'
opts.stek_allow_reuse = 30
opts.stek_allow_reuse__help = 'How long the stek is allowed to be reused, in days'
opts.retest = false
opts.store_results = true

# validations & options parsing
OptParseGen.parse(opts, ['-h']) if ARGV.empty?
conf = OptParseGen.parse!(opts)

def test(conf)
  if conf.host.empty?
    raise ArgumentError, 'missing Hostname'
  end

  if conf.first_check_tries < 0
    raise ArgumentError, 'first_check_tries needs to be at least 1'
  end

  # funcs

  def extract_master_key(o)
    if o =~ /Master-Key: ([0-9a-fA-F]+)\n/
      $1.downcase
    end
  end
  def extract_ses_id(o)
    if o =~ /Session-ID: ([0-9a-fA-F]+)\n/
      $1.downcase
    end
  end
  def extract_lifetime(o)
    if o =~ /TLS session ticket lifetime hint: (\d+) \(seconds\)/
      $1.to_i
    end
  end
  def extract_ses_token(o)
    if o =~ /TLS session ticket:(?:\s|\n)+0000 - ((?:[0-9a-fA-F-]{2,5} )+)((?:(?!\n\n)(?:.|\n))+)/
      stek = $1.tr(' -', '')
      ticket = $2.scan(/- ((?:[0-9a-f-]{2,5} )+)/).map{|t| t.first.tr(' -', '')}.join
      [stek, ticket]
    end
  end
  def timestamp(conf)
    DateTime.now.strftime(conf.time_format)
  end
  def openssl(conf, *other_args)
    Open3.capture3(*conf.cmd, "#{conf.host}:#{conf.port}", '-servername', conf.host , *other_args)
  end

  conf.start_time = timestamp(conf)
  stdouts = []
  lifetimes = []
  steks = []
  tokens = []
  conf.first_check_tries.times do
    stdout, _stderr, _status = openssl(conf)

    stdouts << stdout
    lifetimes << extract_lifetime(stdout)
    stek, tok = extract_ses_token(stdout)
    tokens << tok
    steks << stek
  end

  if steks.compact.empty? && lifetimes.compact.empty?
    puts 'no session tokens'
    exit 0
  end

  puts 'STEKs: ' << steks.count_unique.to_s
  if steks.uniq.count == conf.first_check_tries && conf.first_check_tries >= 2
    puts 'Differing STEKs for each request, this could be fine'
  elsif steks.uniq.count > 1
    puts 'Differing STEKs detected: probable cause loadbalancing or key change'
    puts '                          consider setting --first-check-tries higher.'
  end

  steks.uniq.each do |s|
    results = File.read(conf.storage_file).scan /[^\n;]+;#{conf.host};#{s}\n/
    if results.any?
      first_seen_date = results.first.split(";").first
      first_seen_date = DateTime.strptime(first_seen_date, conf.time_format)
      if first_seen_date > DateTime.now + conf.stek_allow_reuse
        puts "STEK (" << s << ") was already seen, first at " << first_seen_date
      end
    end
  rescue Errno::ENOENT
  end

  if lifetimes.compact.any?{|l| l > conf.lifetimehint_too_long}
    puts 'long Session ticket lifetime: ' << lifetimes.count_unique.to_s
  else
    puts 'Session ticket lifetime: ' << lifetimes.count_unique.to_s
  end

  if conf.test_lifetime
    Tempfile.create('pfs-test') do |f|
      puts timestamp(conf)
      stdout, _stderr, _status = openssl(conf, '-sess_out', f.path)
      stek, tok = extract_ses_token(stdout)

      puts 'sleeping now for a few secs (' << lifetimes.min.to_s << ') please wait for the test to finish'
      sleep lifetimes.min + conf.test_lifetime_tolerance
      begin
        stdout, _stderr, _status = openssl(conf, '-sess_in', f.path)

        stek2, tok2 = extract_ses_token(stdout)
        raise 'wrong stek' if stek != stek2
        if tok == tok2
          puts timestamp(conf)
          puts 'Warning: session token reuse worked!'
          puts 'Dumping OpenSSL session data for further insepction:\n'
          f.rewind
          p f.read
        else
          puts 'session token reuse: negative, but the session token encryption key was reused!'
        end
      rescue RuntimeError => e
        if e.message == 'wrong stek'
          conf.test_lifetime_retries -= 1
          if conf.test_lifetime_retries < 0
            puts "Everything is fine :)"
          else
            retry
          end
        end
      end
    end
  end

  if conf.store_results
    unless File.exist? conf.storage_file
      File.write(conf.storage_file, "timestamp;domain;stek\n")
    end

    File.open(conf.storage_file, "a") do |f|
      steks.uniq.each do |s|
        f.write([conf.start_time, "#{conf.host}:#{conf.port}", s].join(";"))
        f.write("\n")
      end
    end
  end
end

if conf.retest
  File.readlines(conf.storage_file).drop(1).map{|l| l.split(';')[1]}.uniq.each do |h|
    host, port = h.split(':')
    next if host.include?('localhost')

    config = conf.clone
    config.host = host
    config.port = port
    config.test_lifetime = false

    puts 'testing: ' << host << ':' << port.to_s
    test(conf)
  end
else
  test(conf)
end
