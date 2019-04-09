require 'openssl'

module OpenSSL
  module X509
    class Certificate
      def expired?(t = Time.now)
        self.not_after <= t
      end
    end
  end
end
