SAMPLE_RATE = 1024
SIZE = 16
STDOUT.sync = false

require 'complex'

# https://en.wikipedia.org/wiki/Window_function#Nuttall_window,_continuous_first_derivative
def nuttall_window(size)
  size.times.map do |n|
    0.355768 -
    (0.487396 * Math::cos((Math::PI*2*n)/(size-1))) +
    (0.144232 * Math::cos((Math::PI*4*n)/(size-1))) -
    (0.012604 * Math::cos((Math::PI*6*n)/(size-1)))
  end
end
def hann_window(size)
  size.times.map do |n|
    Math.sin(Math::PI*n/size)**2
  end
end
def hamming_window(size)
  size.times.map do |n|
    (25/46.0)*(1-Math.cos(Math::PI*2*n/size))
  end
end
def welch_window(size)
  size.times.map do |n|
    1 - ((n - (size/2.0))/(size/2.0))**2
  end
end

def broken_welch_window(size)
  size.times.map do |n|
    1 - ((n - (size/2))/(size/2))**2
  end
end



class Array
  # Algorithm from: https://blog.mro.name/2011/04/simple-ruby-fast-fourier-transform/
  def fft(window=false, inverse=false)
    unless self.length.to_s(2).count("1") == 1
      raise ArgumentError.new("Input array size must be a power of two but was '#{self.length}'")
    end
    src = self.dup
    phi = Math::PI / (self.length/2)
    if inverse
      phi = -phi
    else
      window = window ? hamming_window(self.length) : [1]*self.length
      src.map!{|c| window.shift * c / self.length.to_f}
    end

    sin_cos_table = Array.new(self.length/2){|i| Complex(Math.cos(i*phi), Math.sin(i*phi))}

    # bit reordering
    j = 0
    1.upto(self.length - 1) do |i|
      m = self.length / 2
      while j >= m
        j -= m
        m /= 2
      end
      j += m
      src[i],src[j] = src[j],src[i] if j > i
    end

    # 1d(N) Ueberlagerungen
    mm = 1
    n1 = self.length - 1
    n2 = self.length / 2
    begin
      m = mm
      mm *= 2
      0.upto(m - 1) do |k|
        w = sin_cos_table[k*n2]
        k.step(n1, mm) do |i|
          temp = w * src[i+m]
          src[i+m] = src[i] - temp
          src[i] += temp
        end
      end
      n2 /= 2
    end while mm != self.length
    src
  end
end
# ([0]*2).fft.flat_map{|x|[x.real, x.imag]} == [0]*4
# ([0]*4).fft.flat_map{|x|[x.real, x.imag]} == [0]*8
# [1,2,3,4].fft.flat_map{|x|[x.real, x.imag]}
# [-1,1,-1,1].fft.flat_map{|x|[x.real, x.imag]} == [0,0,0,0,-1,-0,0,0]
# ([1]*8).fft.flat_map{|x|[x.real, x.imag]} == [1]+[0]*15
# ([3.2]*4).fft.flat_map{|x|[x.real, x.imag]} == [3.2]+[0]*7

require '~/dev/me/lib/ruby/stdlib/color_palette.rb'
def color(x)
  # color_to_ansi(*color_palette(y = Math.log([1, 1+x].max)/8.3 )) rescue raise [x,y].to_s # this is for s16le (int16)
  color_to_ansi(*color_palette(y = (Math.log(1+(x*(10**4.5)).abs))/8.3 )) rescue raise [x,y].to_s # this is for float32le
end

require 'open3'
# stdin, stream, stderr, _wait_thr = Open3.popen3("parecord", "--channels=1", "--raw", "--rate=#{SAMPLE_RATE}", "--format=s16le")
stdin, stream, stderr, _wait_thr = Open3.popen3("parecord", "--channels=1", "--raw", "--rate=#{SAMPLE_RATE}", "--format=float32le")
stdin.close
stderr.close

step = SAMPLE_RATE/8
buffer = [0]*SAMPLE_RATE
loop do
  buffer.slice!(0,step)
  # buffer.push(*stream.read(step*2).unpack("s<*")) # s16le
  buffer.push(*stream.read(step*4).unpack("e*")) # float32le
  print(*buffer.fft(true).slice(0,SAMPLE_RATE/2).map{|c| color(c.real)+'█'}, "\n")
end
