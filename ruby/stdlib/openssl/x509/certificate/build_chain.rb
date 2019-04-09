require 'openssl'
require_relative 'load_parent'
require_relative 'self_signed?'

module OpenSSL
  module X509
    class Certificate
      def build_chain(**opts)
        chain = [self]
        while not chain.last.self_signed?
          begin
            chain.append(chain.last.load_parent(opts))
          rescue RuntimeError => e
            msg = ['no parent, is self signed', 'no way to get parent ;_;']
            break if msg.include?(e.message)
          end
        end
        # debug
        # puts chain
        chain
      end
    end
  end
end
