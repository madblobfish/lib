class Array
  def rotate_2d
    self.transpose.map(&:reverse)
  end
end

raise "AHH" unless ([['#','#','#'],[' ',' ','#']]).rotate_2d() == [[' ','#'],[' ','#'],['#','#']]
