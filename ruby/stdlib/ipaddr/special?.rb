require 'ipaddr'

class IPAddr
  public def special?
    ip = self.dup
    ip.prefix = 32
    (ipv6? ? BLOCKS6 : BLOCKS4).select{|b| b[:"Address Block"].include?(ip)}
  end

  public def name
    self.special?&.send(:"[]", :"Name")
  end
  public def forwardable?
    self.special?&.send(:"[]", :"Forwardable")
  end
  public def global?
    self.special?&.send(:"[]", :"Global")
  end
  public def reserved_by_protocol?
    self.special?&.send(:"[]", :"Reserved-by-Protocol")
  end

  public def useable_as_destination?
    self.special?&.send(:"[]", :"Destination")
  end
  public def useable_as_source?
    self.special?&.send(:"[]", :"Source")
  end

  # blocks generated from https://www.rfc-editor.org/rfc/rfc6890.txt by
  # s.gsub(/^[^|+]+$/, "") # remove everything that does not look like key value fields in the tables
  #  .gsub(/^ +\| (((?!  ).)+) +\| +(((?!  ).)+) *\|$/, '\1: \3') # simplyfy markup for key & value
  #  .gsub(/^[^:]+$/,'')
  #  .gsub(/(?!^) +\n/, "\n") # remove trailing spaces
  #  .gsub(/ ?\[\d\]/, '') # remove references
  #  .gsub(/^([^:\n]+): /, '"\1": ') # quote all keys
  #  .gsub("True","true").gsub("False","false")
  #  .gsub(/: (((?!(  |true|false)).)+)$/, ': "\1"') # quote all values not true or false
  #  .gsub(/"Address Block": ("[^"]+")/, '"Address Block": IPAddr.new(\1)') # make ip's out of the addr blocks
  #  .gsub(/^\n.+?Phone.+?\n$/,'') # remove quirky phone thing
  #  .gsub("\n\n", "\0").gsub("\n",", ").gsub("\0","},\n{").gsub(/,\s*\Z/,'}') # format to object
  #  .gsub("{\"Attribute\": \"Value\"},\n",'') # remove header fields

  BLOCKS4 = [
    {"Address Block": IPAddr.new("0.0.0.0/8"), "Name": "This host on this network", "RFC": "[RFC1122], Section 3.2.1.3", "Allocation Date": "September 1981", "Termination Date": "N/A",
      "Source": true, "Destination": false, "Forwardable": false, "Global": false, "Reserved-by-Protocol": true},
    {"Address Block": IPAddr.new("10.0.0.0/8"), "Name": "Private-Use", "RFC": "[RFC1918]", "Allocation Date": "February 1996", "Termination Date": "N/A",
      "Source": true, "Destination": true, "Forwardable": true, "Global": false, "Reserved-by-Protocol": false},
    {"Address Block": IPAddr.new("100.64.0.0/10"), "Name": "Shared Address Space", "RFC": "[RFC6598]", "Allocation Date": "April 2012", "Termination Date": "N/A",
      "Source": true, "Destination": true, "Forwardable": true, "Global": false, "Reserved-by-Protocol": false},
    {"Address Block": IPAddr.new("127.0.0.0/8"), "Name": "Loopback", "RFC": "[RFC1122], Section 3.2.1.3", "Allocation Date": "September 1981", "Termination Date": "N/A",
      "Source": false, "Destination": false, "Forwardable": false, "Global": false, "Reserved-by-Protocol": true},
    {"Address Block": IPAddr.new("169.254.0.0/16"), "Name": "Link Local", "RFC": "[RFC3927]", "Allocation Date": "May 2005", "Termination Date": "N/A",
      "Source": true, "Destination": true, "Forwardable": false, "Global": false, "Reserved-by-Protocol": true},
    {"Address Block": IPAddr.new("172.16.0.0/12"), "Name": "Private-Use", "RFC": "[RFC1918]", "Allocation Date": "February 1996", "Termination Date": "N/A",
      "Source": true, "Destination": true, "Forwardable": true, "Global": false, "Reserved-by-Protocol": false},
    {"Address Block": IPAddr.new("192.0.0.0/24"), "Name": "IETF Protocol Assignments", "RFC": "Section 2.1 of this document", "Allocation Date": "January 2010", "Termination Date": "N/A",
      "Source": false, "Destination": false, "Forwardable": false, "Global": false, "Reserved-by-Protocol": false},
    {"Address Block": IPAddr.new("192.0.0.0/29"), "Name": "DS-Lite", "RFC": "[RFC6333]", "Allocation Date": "June 2011", "Termination Date": "N/A",
      "Source": true, "Destination": true, "Forwardable": true, "Global": false, "Reserved-by-Protocol": false},
    {"Address Block": IPAddr.new("192.0.2.0/24"), "Name": "Documentation (TEST-NET-1)", "RFC": "[RFC5737]", "Allocation Date": "January 2010", "Termination Date": "N/A",
      "Source": false, "Destination": false, "Forwardable": false, "Global": false, "Reserved-by-Protocol": false},
    {"Address Block": IPAddr.new("192.88.99.0/24"), "Name": "6to4 Relay Anycast", "RFC": "[RFC3068]", "Allocation Date": "June 2001", "Termination Date": "N/A",
      "Source": true, "Destination": true, "Forwardable": true, "Global": true, "Reserved-by-Protocol": false},
    {"Address Block": IPAddr.new("192.168.0.0/16"), "Name": "Private-Use", "RFC": "[RFC1918]", "Allocation Date": "February 1996", "Termination Date": "N/A",
      "Source": true, "Destination": true, "Forwardable": true, "Global": false, "Reserved-by-Protocol": false},
    {"Address Block": IPAddr.new("198.18.0.0/15"), "Name": "Benchmarking", "RFC": "[RFC2544]", "Allocation Date": "March 1999", "Termination Date": "N/A",
      "Source": true, "Destination": true, "Forwardable": true, "Global": false, "Reserved-by-Protocol": false},
    {"Address Block": IPAddr.new("198.51.100.0/24"), "Name": "Documentation (TEST-NET-2)", "RFC": "[RFC5737]", "Allocation Date": "January 2010", "Termination Date": "N/A",
      "Source": false, "Destination": false, "Forwardable": false, "Global": false, "Reserved-by-Protocol": false},
    {"Address Block": IPAddr.new("203.0.113.0/24"), "Name": "Documentation (TEST-NET-3)", "RFC": "[RFC5737]", "Allocation Date": "January 2010", "Termination Date": "N/A",
      "Source": false, "Destination": false, "Forwardable": false, "Global": false, "Reserved-by-Protocol": false},
    {"Address Block": IPAddr.new("240.0.0.0/4"), "Name": "Reserved", "RFC": "[RFC1112], Section 4", "Allocation Date": "August 1989", "Termination Date": "N/A",
      "Source": false, "Destination": false, "Forwardable": false, "Global": false, "Reserved-by-Protocol": true},
    {"Address Block": IPAddr.new("255.255.255.255/32"), "Name": "Limited Broadcast", "RFC": "[RFC0919], Section 7", "Allocation Date": "October 1984", "Termination Date": "N/A",
      "Source": false, "Destination": true, "Forwardable": false, "Global": false, "Reserved-by-Protocol": true}
  ]
  # IPv6
  BLOCKS6 = [
    {"Address Block": IPAddr.new("::1/128"), "Name": "Loopback Address", "RFC": "[RFC4291]", "Allocation Date": "February 2006", "Termination Date": "N/A",
     "Source": false, "Destination": false, "Forwardable": false, "Global": false, "Reserved-by-Protocol": true},
    {"Address Block": IPAddr.new("::/128"), "Name": "Unspecified Address", "RFC": "[RFC4291]", "Allocation Date": "February 2006", "Termination Date": "N/A",
     "Source": true, "Destination": false, "Forwardable": false, "Global": false, "Reserved-by-Protocol": true},
    {"Address Block": IPAddr.new("64:ff9b::/96"), "Name": "IPv4-IPv6 Translat.", "RFC": "[RFC6052]", "Allocation Date": "October 2010", "Termination Date": "N/A",
     "Source": true, "Destination": true, "Forwardable": true, "Global": true, "Reserved-by-Protocol": false},
    {"Address Block": IPAddr.new("::ffff:0:0/96"), "Name": "IPv4-mapped Address", "RFC": "[RFC4291]", "Allocation Date": "February 2006", "Termination Date": "N/A",
     "Source": false, "Destination": false, "Forwardable": false, "Global": false, "Reserved-by-Protocol": true},
    {"Address Block": IPAddr.new("100::/64"), "Name": "Discard-Only Address Block", "RFC": "[RFC6666]", "Allocation Date": "June 2012", "Termination Date": "N/A",
     "Source": true, "Destination": true, "Forwardable": true, "Global": false, "Reserved-by-Protocol": false},
    {"Address Block": IPAddr.new("2001::/23"), "Name": "IETF Protocol Assignments", "RFC": "[RFC2928]", "Allocation Date": "September 2000", "Termination Date": "N/A",
     "Source": false, "Destination": false, "Forwardable": false, "Global": false, "Reserved-by-Protocol": false},
    {"Address Block": IPAddr.new("2001::/32"), "Name": "TEREDO", "RFC": "[RFC4380]", "Allocation Date": "January 2006", "Termination Date": "N/A",
     "Source": true, "Destination": true, "Forwardable": true, "Global": "n/A", "Reserved-by-Protocol": false},
    {"Address Block": IPAddr.new("2001:2::/48"), "Name": "Benchmarking", "RFC": "[RFC5180]", "Allocation Date": "April 2008", "Termination Date": "N/A",
     "Source": true, "Destination": true, "Forwardable": true, "Global": false, "Reserved-by-Protocol": false},
    {"Address Block": IPAddr.new("2001:db8::/32"), "Name": "Documentation", "RFC": "[RFC3849]", "Allocation Date": "July 2004", "Termination Date": "N/A",
     "Source": false, "Destination": false, "Forwardable": false, "Global": false, "Reserved-by-Protocol": false},
    {"Address Block": IPAddr.new("2001:10::/28"), "Name": "ORCHID", "RFC": "[RFC4843]", "Allocation Date": "March 2007", "Termination Date": "March 2014",
     "Source": false, "Destination": false, "Forwardable": false, "Global": false, "Reserved-by-Protocol": false},
    {"Address Block": IPAddr.new("2002::/16"), "Name": "6to4", "RFC": "[RFC3056]", "Allocation Date": "February 2001", "Termination Date": "N/A",
     "Source": true, "Destination": true, "Forwardable": true, "Global": "n/A", "Reserved-by-Protocol": false},
    {"Address Block": IPAddr.new("fc00::/7"), "Name": "Unique-Local", "RFC": "[RFC4193]", "Allocation Date": "October 2005", "Termination Date": "N/A",
     "Source": true, "Destination": true, "Forwardable": true, "Global": false, "Reserved-by-Protocol": false},
    {"Address Block": IPAddr.new("fe80::/10"), "Name": "Linked-Scoped Unicast", "RFC": "[RFC4291]", "Allocation Date": "February 2006", "Termination Date": "N/A",
     "Source": true, "Destination": true, "Forwardable": false, "Global": false, "Reserved-by-Protocol": true}
  ]
end

if __FILE__ == $PROGRAM_NAME
  if not ARGV.one?
    puts 'special?.rb <ip address>'
    puts 'takes a single ip and gives information about it (ignores the block size)'
    puts ''
    puts 'example inputs: 10.0.0.2 0.0.0.0 127.0.0.1 10.0.0.192/26'
    exit
  end
  info = IPAddr.new(ARGV.first).special?
  exit 1 if info.nil?
  puts info.map{|e|e.map{|k,v| "#{k}: #{v}#{"/#{v.prefix}" rescue ""}"}.join("\n")}.join("\n\n")
end
