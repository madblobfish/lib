require 'openssl'
require_relative 'build_chain'
require_relative 'chain_verify'

module OpenSSL
  module X509
    class Certificate
      def build_and_validate_chain(**opts)
        chain = []
        errors = []
        begin
          chain = self.build_chain(opts)
        rescue RuntimeError => e
          errors << "could not build full chain, validating anyway"
        end
        errors + OpenSSL::X509::Certificate.chain_verify(chain, opts)
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  if ARGV.empty?
    puts 'check_cert_chain.rb <path to cert>'
    exit
  end
  puts "checking #{ARGV.first}"

  if ARGV =~ /\.p12$/
    puts 'pkcs12 file detected, trying to extract the certificate'
    `openssl pkcs12 -in #{ARGV} -out /tmp/newfile.crt.pem -clcerts -nokeys`
    ARGV = '/tmp/newfile.crt.pem'
  end
#  if ARGV =~ /\.pem$/
#    `openssl asn1parse -in #{ARGV}`
#  end

  begin
    errors = OpenSSL::X509::Certificate.new(File.read(ARGV.first) << "\n").build_and_validate_chain
    print "\t", errors.join("\t")
  rescue RuntimeError => e
    print "\t#{e}"
    exit 2
  end
  if errors.any?
    puts "\tNOT OK"
    exit 2
  else
    puts "\tOK"
  end
end
