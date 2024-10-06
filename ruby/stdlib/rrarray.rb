## Round Robin Array implementation
class RRArray
  attr_reader :size
  alias :length :size

  def initialize(size)
    @index = 0
    @size = size
    @arr = Array.new(size)
  end

  def inspect
    "#RRArray #{@arr.inspect} @#{@index}"
  end

  def add(elem)
    @arr[@index] = elem
    @index += 1
    @index %= @size
    nil
  end

  def delete(elem)
    return false if elem.nil?
    changed = false
    @arr.map! do |e|
      if e == elem
        changed = true
        nil
      else
        e
      end
    end
    changed
  end

  def delete_last
    @index += @size -1
    @index %= @size
    elem = @arr[@index]
    @arr[@index] = nil
    elem
  end

  def include?(elem)
    # with prefill we can not detect nil's
    return false if elem.nil?
    @arr.include?(elem)
  end
end

a = RRArray.new(5)
raise 'aH' unless a.size == 5 && a.length == 5
raise 'aHH' unless a.add(4) == nil && a.add(2) == nil && a.include?(4)
raise 'aHHH' if a.include?(5) || a.include?(nil)
raise 'aHHHH' unless a.add(nil) == nil && ! a.include?(nil)
raise 'aHHHHH' unless a.delete_last == nil && ! a.include?(nil)
raise 'aHHHHHH' unless a.delete(4) == true && ! a.include?(4)
raise 'aHHHHHHH' unless a.include?(2)
raise 'aHHHHHHHH' unless a.size == 5 && a.length == 5
