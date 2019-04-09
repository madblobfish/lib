require 'openssl'

module OpenSSL
  module X509
    class Certificate
      def extension_by_oid(oid)
        self.extensions.detect{|a| a.oid == oid}&.value
      end
    end
  end
end
