require 'openssl'
require_relative 'subjectKeyIdentifier'
require_relative 'authorityKeyIdentifier'

module OpenSSL
  module X509
    class Certificate
      def is_parent?(other)
        ski = other.subjectKeyIdentifier
        aki = self.authorityKeyIdentifier
        unless ski.nil? || aki.nil?
          return false unless aki == ski
        end
        return false unless self.issuer == other.subject
        self.verify(other.public_key)
      end
    end
  end
end