require 'openssl'
require_relative 'authorityKeyIdentifier'
require_relative 'load_from_truststore_by_ski'

module OpenSSL
  module X509
    class Certificate
      def load_parent_from_truststore
        OpenSSL::X509::Certificate.load_from_truststore_by_ski(self.authorityKeyIdentifier)
      end
    end
  end
end
