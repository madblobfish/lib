require 'openssl'
require_relative 'subjectKeyIdentifier'
require_relative 'load_from_truststore_by_ski'

module OpenSSL
  module X509
    class Certificate
      def in_truststore?
        not OpenSSL::X509::Certificate.load_from_truststore_by_ski(self.subjectKeyIdentifier).nil?
      end
    end
  end
end
