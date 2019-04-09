require 'openssl'
require_relative 'authorityKeyIdentifier'
require_relative 'load_parent_from_truststore'
require_relative 'self_signed?'
require_relative 'is_parent?'
require_relative 'extension_by_oid'
require 'fileutils'

module OpenSSL
  module X509
    class Certificate
      # tries various options to get the parent certificate
      # Note this does use network and caches certificates locally!
      def load_parent(**opts)
        raise 'no parent, is self signed' if self.self_signed?

        if self.authorityKeyIdentifier && !opts[:no_cache]
          FileUtils.mkdir_p("#{ENV['HOME']}/.cache/certs")
          cached_parent = "#{ENV['HOME']}/.cache/certs/cert_#{self.authorityKeyIdentifier}.crt"
          if File.exists?(cached_parent)
            parent = OpenSSL::X509::Certificate.new(File.read(cached_parent))
            return parent unless parent.nil?
          end
        end

        begin
          require 'net/http'
          if aia = self.extension_by_oid('authorityInfoAccess')
            url = aia.split("\n").grep(/CA Issuers/).first
            unless url.nil?
              uris = URI.extract(url, ['http', 'https', 'HTTP', 'HTTPS']).first
              resp = Net::HTTP.get(URI(uris))
              parent = OpenSSL::X509::Certificate.new(resp) rescue nil
              parent = OpenSSL::PKCS7.new(resp).certificates.detect{|c| self.is_parent?(c)} if parent.nil? rescue nil
              File.write(cached_parent, parent) if cached_parent && !opts[:no_cache]
              return parent unless parent.nil?
            end
          end
        rescue
        end
        unless opts[:no_truststore]
          parent = self.load_parent_from_truststore
          return parent unless parent.nil?
        end
        if self.authorityKeyIdentifier
          # last resort though crt.sh

          parent = Net::HTTP.get(URI("https://crt.sh?ski=#{self.authorityKeyIdentifier}"))
            .scan(/\?id=([0-9]+)/).map(&:first)
            .reverse
            .map{|id| OpenSSL::X509::Certificate.new(Net::HTTP.get(URI("https://crt.sh?d=#{id}"))) rescue nil}
            .compact
            .detect{|c| self.is_parent?(c)}
          File.write(cached_parent, parent) if cached_parent && !opts[:no_cache]
          return parent unless parent.nil?
        else
          raise 'no way to get parent ;_;'
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  unless ARGV.one?
    puts 'check_cert_chain.rb <path to cert to try to find parent>'
    exit
  end

  puts OpenSSL::X509::Certificate.new(readlines(nil).first).load_parent
end
