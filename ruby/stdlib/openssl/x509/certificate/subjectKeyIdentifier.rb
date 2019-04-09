require 'openssl'
require_relative 'extension_by_oid'

module OpenSSL
  module X509
    class Certificate
      def subjectKeyIdentifier
        self.extension_by_oid('subjectKeyIdentifier')
      end
    end
  end
end
