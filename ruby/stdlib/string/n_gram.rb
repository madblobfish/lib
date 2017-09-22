class String
  def n_gramify(n=3)
    return [] if self.length < n

    out = []
    for i in 0..(self.length-n)
      out.push self[i, n]
    end
    out
  end

  def n_gram_distance(other, n=3)
    self_n = self.n_gramify(n)
    other_n = other.n_gramify(n)

    indices = self_n.map{|gram| idx = other_n.index(gram); other_n.delete_at(idx) unless idx.nil?; idx}
    indices.compact!
    (2 * indices.length) / (self_n.length + other_n.length).to_f
  end
end
