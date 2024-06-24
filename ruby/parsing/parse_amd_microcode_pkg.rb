
def parse_amd_microcode_pkg(path)
  regexp = /(?<date>.\x20[\x01-\x31][\x01-\x13])(?<version>.{4})(?<loaderid>[\x00-\x04]\x80)(?<size>[\x00\x20\x10])(?<initflag>[\x00\x01])(?<checksum>.{4})(?<nb_vendor_id>(\x00{2}|\x22\x10))(?<nb_dev_id>.{2})(?<sb_vendor_id>(\x00{2}|\x22\x10))(?<sb_dev_id>..)(?<processor_sig>..)(?<nb_rev_id>.)(?<sb_rev_id>.)(?<bios_rev>[\x00\x01])(\x00{3}|\xAA{3})/mn
  bin_to_hex = lambda{|b| b.unpack("C*").map{|x|(x+256).to_s(16)[1,2]} }

  file = File.open(path, mode:'rb')
  raise 'wrong file format' if file.read(4) != "DMA\x00"
  cpu_table_type = file.read(4).unpack1('I')
  raise 'unkown cpu table type' if cpu_table_type != 0
  header_size = file.read(4).unpack1('I') + 4*3

  File.read(path, mode:"rb").scan(regexp).map do |date, version, loaderid, size, _, checksum, nb_vendor_id, nb_dev_id, sb_vendor_id, sb_dev_id, processor_sig, nb_rev_id, sb_rev_id, bios_rev|
    year = bin_to_hex[date[0,2]].reverse.join
    {
      date: year + '-' + bin_to_hex[date[2,2]].reverse.join("-"),
      version: version.unpack("L<").first.to_s(16),
      loaderid: bin_to_hex[loaderid].join(''),
      size: bin_to_hex[size].join(''),
      checksum: bin_to_hex[checksum].join(''),
      nb_vendor_id: bin_to_hex[nb_vendor_id].join(''),
      nb_dev_id: bin_to_hex[nb_dev_id].join(''),
      sb_vendor_id: bin_to_hex[sb_vendor_id].join(''),
      sb_dev_id: bin_to_hex[sb_dev_id].join(''),
      processor_sig: bin_to_hex[processor_sig].join(''),
      nb_rev_id: bin_to_hex[nb_rev_id].join(''),
      sb_rev_id: bin_to_hex[sb_rev_id].join(''),
      bios_rev: bin_to_hex[bios_rev].join(''),
    }
  end
end

if __FILE__ == $PROGRAM_NAME
  parse_amd_microcode_pkg(ARGV.first || "/lib/firmware/amd-ucode/microcode_amd.bin").each{|c| p c}
end
