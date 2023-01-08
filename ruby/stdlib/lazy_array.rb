class LazyArray
  module EnumExtension
    refine Enumerable do
      def take_n(n=1)
        out = []
        begin
          n.times{out << self.next}
          return [false, out]
        rescue StopIteration
          return [true, out]
        end
      end
    end
  end
  using EnumExtension
  # item_enum: Enumerator
  # size: of it all
  def initialize(item_enum, size)
    @array = []
    @compact = false
    @enum = item_enum.lazy
    @eof = false
    @order = size.times.to_a
    @orig_size = size
    @shuffled = false
    @taken = -1
  end
  # def array
  #   @array
  # end
  # def order
  #   @order
  # end
  def size
    @order.size
  end
  def purge_index(idx, remove=false)
    @array.delete_at(@order[idx]) if remove
    if idx.respond_to?('to_ary')
      @order -= idx.to_ary
      @order.map!{|v| v - idx.count{|i| v > i}}
    else # single item
      @order.delete(idx)
      @order.map!{|v| v > idx ? v-1 : v}
    end
    nil
  end
  def compact
    if @compact == false
      # @enum = @enum.reject(&:nil?) #compact does not work here for some reason
      @array.reject!.with_index{|e, i| e.nil? ? (purge_index(i); true) : false}
      @compact = true
    end
    self
  end
  def reject!
    @enum = @enum.reject{|x|yield x}
  end
  def shuffle!
    @shuffled = true
    @order.shuffle!
    self
  end
  def [](num)
    return nil if num >= size
    if @order[num] > @taken
      return nil if @eof
      count = @order[num] - @taken
      empty, elements = @enum.take_n(count)
      @array += elements
      @taken += elements.count
      if empty
        @eof = true
        @order -= (@taken+1..@orig_size).to_a
      end
    end
    @array[@order[num]] rescue nil
  end
  def first
    self[0]
  end
  def last
    self[-1]
  end
end

# a = LazyArray.new([1,2,3,4,nil,"hai",7], 7) #.compact.shuffle!
# puts "e0: #{a[0].inspect}"
# puts "e1: #{a[1].inspect}"
# puts "e0: #{a[0].inspect}"
# puts "e3: #{a[3].inspect}"
# puts "size: #{a.size}"
# puts "e1: #{a[1].inspect}"
# puts "e3: #{a[3].inspect}"
# puts "e0: #{a[0].inspect}"
# puts "e4: #{a[4].inspect}"
# puts "e2: #{a[2].inspect}"
# puts "e5: #{a[5].inspect}"
# puts "e9: #{a[6].inspect}"
# puts "size: #{a.size}"
# # # only when order and array methods are uncommented
# # puts "o: #{a.order.inspect}"
# # puts "A: #{a.array.inspect} #{a.array.length}"
