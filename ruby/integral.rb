
# calculates the area under a function using the trapezial method
# making h smaller schould give higher precision
def trapezial(a, b, h, &func)
  range = [a, b].max - [a, b].min;
  sum = 0
  schritt = [a, b].min

  (0..(range/h)).each do |i|
    value = func.call(schritt).to_f
    case i
    when 0, (range/h).to_i
      sum += value/2
    else
      sum += value
    end
    schritt += h
  end
  return h * sum
end

# h goes up; result gets closer to 2
# trapezial(0, Math::PI, 0.05){|x|Math.sin(x)}
#=> 1.9987186464290039
# trapezial(0, Math::PI, 0.00001){|x|Math.sin(x)}
# => 1.9999999999710953

# for better results think about implementing automatic differentation
# https://codon.com/automatic-differentiation-in-ruby
# https://github.com/tomstuart/dual_number
