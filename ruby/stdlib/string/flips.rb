
class String
	def flips
		[''].product(*self.split('').map{|c|[c.downcase, c.upcase].uniq}) do |c|
			if block_given?
				yield c.join
			else
				puts c.join
			end
		end
	end
end
