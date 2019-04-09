require 'openssl'
require_relative 'extension_by_oid'

module OpenSSL
  module X509
    class Certificate
      def authorityKeyIdentifier
        self.extension_by_oid("authorityKeyIdentifier")&.gsub(/^(?:keyid:)?.*?([a-fA-F0-9:]+).*?$/, '\1')&.strip
      end
    end
  end
end
