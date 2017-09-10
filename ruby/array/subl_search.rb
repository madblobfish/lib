class Array
  def subl_search(string)
    self.grep /#{string.split('').join('.*')}/
  end
end
