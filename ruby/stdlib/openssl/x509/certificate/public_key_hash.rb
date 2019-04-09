require 'openssl'

module OpenSSL
  module X509
    class Certificate
      def public_key_hash
        Digest::SHA256.hexdigest(self.public_key.to_der)
      end
    end
  end
end
