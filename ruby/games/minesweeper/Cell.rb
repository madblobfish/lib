class Cell
  def initialize state = '#'
    raise 'Bad state' unless %w(+ #).include? state
    @state = state
  end

  def sweep point, field
    raise BOOOM if '+' == @state && @state = '*'
    return 0 if @state != '#'
    @state = field.reduce_surround(point){ |n, cp|
      cp[0].increment_if_mine n
    }.to_s
    1 + auto_reveal(point, field)
  end

  def auto_reveal point, field
    return 0 if @state != '0'
    field.reduce_surround(point){ |n, cp|
      n + cp[0].sweep(cp[1], field)
    }
  end

  def increment_if_mine n
    @state == '+' ? n + 1 : n
  end

  def p
    print @state == '+' ? '#' : @state
  end
end
class BOOOM < StandardError;end
