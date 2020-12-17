class IO
  # takes a blocksize and calls block with:
  # * slice of date of blocksize or less (last one)
  # * bool if first
  # * bool if last (note both can be true)
  def each_block(blocksize, &block)
    first, next_block = true
    previous_block = read(blocksize)
    while next_block
      next_block = read(blocksize)
      yield previous_block, first, next_block.nil?
      first = false
      previous_block = next_block
    end
  end
end
