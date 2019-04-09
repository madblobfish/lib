require 'openssl'
require_relative 'expired?'
require_relative 'self_signed?'
require_relative 'cert_on_symantec_blacklist'

module OpenSSL
  module X509
    class Certificate
        def self.chain_verify(chain, **opts)
        errors = []
        errors << 'last cert in chain not selfsigned' unless chain.last.self_signed?
        errors << 'a cert in the chain is expired' if chain.map(&:expired?).count(true) >= 1

        unless opts[:no_check_symantec_blacklist]
          if chain.map(&:cert_on_symantec_blacklist).count(true) >= 1
            errors << 'a cert is on the symantec blacklist!'
          end
        end

        File.write('/tmp/ca.pem', chain.last.to_pem)
        File.write('/tmp/cert.pem', chain.first.to_pem)
        File.write('/tmp/inter.pem', chain[1...-1].map(&:to_pem).join("\n"))

        intermediates = File.empty?('/tmp/inter.pem') ? '' : '-untrusted /tmp/inter.pem'
        out = `openssl verify -purpose sslserver -CAfile /tmp/ca.pem #{intermediates} /tmp/cert.pem 2>/dev/null`
        errors << 'openssl verify failed' unless out == "/tmp/cert.pem: OK\n" && $?.success?
        errors
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  if ARGV.empty?
    puts 'check_cert_chain.rb <path to certs>'
    exit
  end

  errors = OpenSSL::X509::Certificate.chain_verify(readlines(nil).map{|c|OpenSSL::X509::Certificate.new(c)})
  puts errors

  if errors.any?
    puts 'NOT OK'
    exit 2
  else
    puts 'OK'
  end
end
