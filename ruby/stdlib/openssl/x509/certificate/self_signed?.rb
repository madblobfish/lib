require 'openssl'
require_relative 'is_parent?'

module OpenSSL
  module X509
    class Certificate
      def self_signed?
        self.is_parent?(self)
      end
    end
  end
end
