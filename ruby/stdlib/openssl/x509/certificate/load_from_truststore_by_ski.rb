require 'openssl'
require_relative 'subjectKeyIdentifier'

module OpenSSL
  module X509
    class Certificate
      # certfolder could be e.g. from https://github.com/nabla-c0d3/trust_stores_observatory
      def self.load_from_truststore_by_ski(ski, certfolder = "#{ENV['HOME']}/dev/opensource/trust_stores_observatory/certificates/")
        trusts = Dir[certfolder + "/*"]
          .map{|f| OpenSSL::X509::Certificate.new(File.read(f)) rescue nil}.compact
          .group_by{|c|c.subjectKeyIdentifier}[ski]&.first
      end
    end
  end
end
