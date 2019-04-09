Dir[(__FILE__).gsub(/.rb\z/, '/*.rb')].each{|f| require_relative f}
