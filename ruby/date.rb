# Date According To Eris

B62_CHARS = %w(0 1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)
class Integer
  def to_base(b=61, chars=B62_CHARS)
    (negative? ? '-' : '') + self.each_digit(b).map{|x|chars[x]}.reverse.join('')
  end
  def each_digit(base=10)
    ret = []
    num = self.abs
    while num != 0
      if block_given?
        yield(num % base)
      else
        ret += [num % base]
      end
      num /= base
    end
    ret
  end
end
class String
  def from_base(base=61, chars=B62_CHARS)
    self.reverse.each_char.with_index.reduce(0){|m,(c,i)|m+chars.index(c)*((base)**i)}
  end
  def rsplit(*args)
    self.reverse.split(*args).map(&:reverse).reverse
  end
end

def _date_ymd(time=Time.now)
  %i(year month day).map{|e|time.send(e).to_base}.join
end
def _date_hms(time=Time.now)
  '-'+%i(hour min sec).map{|e|time.send(e).to_base}.join
end
def _date_n(time=Time.now)
  ".#{time.nsec.to_base}"
end
def _date_tz(time=Time.now)
  '+'+time.gmtoff.to_base
end
def date(time=Time.now, **o)
  "#{_date_ymd(time)}#{_date_hms(time) if %i(hms n).include?(o[:p])}#{_date_n(time) if o[:p]==:n}#{_date_tz(time) if o[:tz]}"
end

def date_parse(string)
  negative = string[0] == '-' ? -1 : 1
  string.chop if negative.negative?
  datetime, tz = string.split('+', 2)
  date, time = datetime.split('-', 2)
  raise 'time part needs to be 3 characters' if time && time&.length != 3
  raise 'date part needs to be at least 3 characters' unless date.length >= 3
  y,m,d = date.rsplit('', 3)
  t = Time.new(negative*y.from_base,*[m,d,*time&.split(''),tz].map{|x|x&.from_base})
  # validation to make dates properly reference only a single point in time
  raise ArgumentError, 'argument out of range' if t.month != m.from_base
  t
end

def date_valid?(string)
  date_parse(string) rescue return false
  true
end

def date_valid_regexp?(string)
  /\A\w+[1-9a-c][1-9a-w](-[0-9a-n][0-9a-zA-X]{2}(\.\w{3,}))?(\+\w)?\z/ =~ string
end

if ARGV.one?
  p date_parse(ARGV[0])
else
  puts date(p: :hms)
end
