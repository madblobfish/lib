class String
  def contains_japanese?
    # with kanji
    # /[\u3000-\u303f\u3040-\u309f\u30a0-\u30ff\uff00-\uff9f\u4e00-\u9faf\u3400-\u4dbf]/.match?(self)
    /[\u3000-\u303f\u3040-\u309f\u30a0-\u30ff\uff00-\uff19\uff1b-\uff9f]/.match?(self)
  end
end
