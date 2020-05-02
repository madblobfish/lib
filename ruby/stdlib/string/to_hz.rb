class String
  def to_key_number
    number = self[-1].to_i * 12 -8
    number += "C D EF G A H".index(self.chr.tr('B','H'))
    if self.length == 3
      number += 1 if /[#♯]/ =~ self[1]
      number -= 1 if /[b♭]/ =~ self[1]
    end
    number
  end
  
  def to_hz
    2**((to_key_number-49.0)/12)*440
  end
end

raise "to_hz test failed" unless "A4".to_hz == 440
raise "to_hz test failed" unless "A#0".to_key_number == 2
raise "to_hz test failed" unless "B#0".to_hz == "H#0".to_hz
