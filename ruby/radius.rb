# RADIUS base spec: https://datatracker.ietf.org/doc/html/rfc2865
# RADIUS Implementation Issues and Suggested Fixes: https://datatracker.ietf.org/doc/html/rfc5080
# RADIUS Extensions (Support for EAP!): https://datatracker.ietf.org/doc/html/rfc2869#section-2.3
# RADIUS extended Attributes https://www.rfc-editor.org/rfc/rfc6929.html#section-3

# alternative?
# https://datatracker.ietf.org/doc/html/rfc5191
# http://www.ijsrp.org/research-paper-0713/ijsrp-p1975.pdf

#*eap ttls: https://datatracker.ietf.org/doc/html/rfc5281#section-5
# eap: https://datatracker.ietf.org/doc/html/rfc3748
# eap pap: https://www.rfc-editor.org/rfc/rfc1334#section-2

# clients:
#   https://github.com/CESNET/rad_eap_test
#   eapol_test (from wpa_supplicant)

require 'openssl'
require 'socket'
require 'stringio'

SECRET = 's3cr3t'
USERS = {'user'=>'password'}

# https://www.iana.org/assignments/radius-types/radius-types.xhtml#radius-types-27
RADIUS_PACKET_CODE = {
  1=> 'Access-Request',
  2=> 'Access-Accept',
  3=> 'Access-Reject',
  4=> 'Accounting-Request',
  5=> 'Accounting-Response',
  6=> 'Accounting-Status (now Interim Accounting)',
  7=> 'Password-Request',
  8=> 'Password-Ack',
  9=> 'Password-Reject',
  10=> 'Accounting-Message',
  11=> 'Access-Challenge',
  # 12=> 'Status-Server (experimental)',
  # 13=> 'Status-Client (experimental)',
  21=> 'Resource-Free-Request',
  22=> 'Resource-Free-Response',
  23=> 'Resource-Query-Request',
  24=> 'Resource-Query-Response',
  25=> 'Alternate-Resource-Reclaim-Request',
  26=> 'NAS-Reboot-Request',
  27=> 'NAS-Reboot-Response',
  #28=> 'Reserved',
  29=> 'Next-Passcode',
  30=> 'New-Pin',
  31=> 'Terminate-Session',
  32=> 'Password-Expired',
  33=> 'Event-Request',
  34=> 'Event-Response',
  40=> 'Disconnect-Request',
  41=> 'Disconnect-ACK',
  42=> 'Disconnect-NAK',
  43=> 'CoA-Request',
  44=> 'CoA-ACK',
  45=> 'CoA-NAK',
  50=> 'IP-Address-Allocate',
  51=> 'IP-Address-Release',
  52=> 'Protocol-Error',
  #250=> '253 Experimental Use',
  #254=> 'Reserved',
  #255=> 'Reserved',
}
RADIUS_PACKET_CODE_INVERT = RADIUS_PACKET_CODE.invert

# https://www.iana.org/assignments/radius-types/radius-types.xhtml#radius-types-2
RADIUS_ATTRIBUTE_TYPE = {
  1=> 'User-Name',
  2=> 'User-Password',
  3=> 'CHAP-Password',
  4=> 'NAS-IP-Address',
  5=> 'NAS-Port',
  6=> 'Service-Type',
  7=> 'Framed-Protocol',
  8=> 'Framed-IP-Address',
  9=> 'Framed-IP-Netmask',
  10=> 'Framed-Routing',
  11=> 'Filter-Id',
  12=> 'Framed-MTU',
  13=> 'Framed-Compression',
  14=> 'Login-IP-Host',
  15=> 'Login-Service',
  16=> 'Login-TCP-Port',
  # 17=> 'Unassigned',
  18=> 'Reply-Message',
  19=> 'Callback-Number',
  20=> 'Callback-Id',
  # 21=> 'Unassigned',
  22=> 'Framed-Route',
  23=> 'Framed-IPX-Network',
  24=> 'State',
  25=> 'Class',
  26=> 'Vendor-Specific',
  27=> 'Session-Timeout',
  28=> 'Idle-Timeout',
  29=> 'Termination-Action',
  30=> 'Called-Station-Id',
  31=> 'Calling-Station-Id',
  32=> 'NAS-Identifier',
  33=> 'Proxy-State',
  34=> 'Login-LAT-Service',
  35=> 'Login-LAT-Node',
  36=> 'Login-LAT-Group',
  37=> 'Framed-AppleTalk-Link',
  38=> 'Framed-AppleTalk-Network',
  39=> 'Framed-AppleTalk-Zone',
  40=> 'Acct-Status-Type',
  41=> 'Acct-Delay-Time',
  42=> 'Acct-Input-Octets',
  43=> 'Acct-Output-Octets',
  44=> 'Acct-Session-Id',
  45=> 'Acct-Authentic',
  46=> 'Acct-Session-Time',
  47=> 'Acct-Input-Packets',
  48=> 'Acct-Output-Packets',
  49=> 'Acct-Terminate-Cause',
  50=> 'Acct-Multi-Session-Id',
  51=> 'Acct-Link-Count',
  52=> 'Acct-Input-Gigawords',
  53=> 'Acct-Output-Gigawords',
  # 54=> 'Unassigned',
  55=> 'Event-Timestamp',
  56=> 'Egress-VLANID',
  57=> 'Ingress-Filters',
  58=> 'Egress-VLAN-Name',
  59=> 'User-Priority-Table',
  60=> 'CHAP-Challenge',
  61=> 'NAS-Port-Type',
  62=> 'Port-Limit',
  63=> 'Login-LAT-Port',
  64=> 'Tunnel-Type',
  65=> 'Tunnel-Medium-Type',
  66=> 'Tunnel-Client-Endpoint',
  67=> 'Tunnel-Server-Endpoint',
  68=> 'Acct-Tunnel-Connection',
  69=> 'Tunnel-Password',
  70=> 'ARAP-Password',
  71=> 'ARAP-Features',
  72=> 'ARAP-Zone-Access',
  73=> 'ARAP-Security',
  74=> 'ARAP-Security-Data',
  75=> 'Password-Retry',
  76=> 'Prompt',
  77=> 'Connect-Info',
  78=> 'Configuration-Token',
  79=> 'EAP-Message',
  80=> 'Message-Authenticator',
  81=> 'Tunnel-Private-Group-ID',
  82=> 'Tunnel-Assignment-ID',
  83=> 'Tunnel-Preference',
  84=> 'ARAP-Challenge-Response',
  85=> 'Acct-Interim-Interval',
  86=> 'Acct-Tunnel-Packets-Lost',
  87=> 'NAS-Port-Id',
  88=> 'Framed-Pool',
  89=> 'CUI',
  90=> 'Tunnel-Client-Auth-ID',
  91=> 'Tunnel-Server-Auth-ID',
  92=> 'NAS-Filter-Rule',
  # 93=> 'Unassigned',
  94=> 'Originating-Line-Info',
  95=> 'NAS-IPv6-Address',
  96=> 'Framed-Interface-Id',
  97=> 'Framed-IPv6-Prefix',
  98=> 'Login-IPv6-Host',
  99=> 'Framed-IPv6-Route',
  100=> 'Framed-IPv6-Pool',
  101=> 'Error-Cause Attribute',
  102=> 'EAP-Key-Name',
  103=> 'Digest-Response',
  104=> 'Digest-Realm',
  105=> 'Digest-Nonce',
  106=> 'Digest-Response-Auth',
  107=> 'Digest-Nextnonce',
  108=> 'Digest-Method',
  109=> 'Digest-URI',
  110=> 'Digest-Qop',
  111=> 'Digest-Algorithm',
  112=> 'Digest-Entity-Body-Hash',
  113=> 'Digest-CNonce',
  114=> 'Digest-Nonce-Count',
  115=> 'Digest-Username',
  116=> 'Digest-Opaque',
  117=> 'Digest-Auth-Param',
  118=> 'Digest-AKA-Auts',
  119=> 'Digest-Domain',
  120=> 'Digest-Stale',
  121=> 'Digest-HA1',
  122=> 'SIP-AOR',
  123=> 'Delegated-IPv6-Prefix',
  124=> 'MIP6-Feature-Vector',
  125=> 'MIP6-Home-Link-Prefix',
  126=> 'Operator-Name',
  127=> 'Location-Information',
  128=> 'Location-Data',
  129=> 'Basic-Location-Policy-Rules',
  130=> 'Extended-Location-Policy-Rules',
  131=> 'Location-Capable',
  132=> 'Requested-Location-Info',
  133=> 'Framed-Management-Protocol',
  134=> 'Management-Transport-Protection',
  135=> 'Management-Policy-Id',
  136=> 'Management-Privilege-Level',
  137=> 'PKM-SS-Cert',
  138=> 'PKM-CA-Cert',
  139=> 'PKM-Config-Settings',
  140=> 'PKM-Cryptosuite-List',
  141=> 'PKM-SAID',
  142=> 'PKM-SA-Descriptor',
  143=> 'PKM-Auth-Key',
  144=> 'DS-Lite-Tunnel-Name',
  145=> 'Mobile-Node-Identifier',
  146=> 'Service-Selection',
  147=> 'PMIP6-Home-LMA-IPv6-Address',
  148=> 'PMIP6-Visited-LMA-IPv6-Address',
  149=> 'PMIP6-Home-LMA-IPv4-Address',
  150=> 'PMIP6-Visited-LMA-IPv4-Address',
  151=> 'PMIP6-Home-HN-Prefix',
  152=> 'PMIP6-Visited-HN-Prefix',
  153=> 'PMIP6-Home-Interface-ID',
  154=> 'PMIP6-Visited-Interface-ID',
  155=> 'PMIP6-Home-IPv4-HoA',
  156=> 'PMIP6-Visited-IPv4-HoA',
  157=> 'PMIP6-Home-DHCP4-Server-Address',
  158=> 'PMIP6-Visited-DHCP4-Server-Address',
  159=> 'PMIP6-Home-DHCP6-Server-Address',
  160=> 'PMIP6-Visited-DHCP6-Server-Address',
  161=> 'PMIP6-Home-IPv4-Gateway',
  162=> 'PMIP6-Visited-IPv4-Gateway',
  163=> 'EAP-Lower-Layer',
  164=> 'GSS-Acceptor-Service-Name',
  165=> 'GSS-Acceptor-Host-Name',
  166=> 'GSS-Acceptor-Service-Specifics',
  167=> 'GSS-Acceptor-Realm-Name',
  168=> 'Framed-IPv6-Address',
  169=> 'DNS-Server-IPv6-Address',
  170=> 'Route-IPv6-Information',
  171=> 'Delegated-IPv6-Prefix-Pool',
  172=> 'Stateful-IPv6-Address-Pool',
  173=> 'IPv6-6rd-Configuration',
  174=> 'Allowed-Called-Station-Id',
  175=> 'EAP-Peer-Id',
  176=> 'EAP-Server-Id',
  177=> 'Mobility-Domain-Id',
  178=> 'Preauth-Timeout',
  179=> 'Network-Id-Name',
  180=> 'EAPoL-Announcement',
  181=> 'WLAN-HESSID',
  182=> 'WLAN-Venue-Info',
  183=> 'WLAN-Venue-Language',
  184=> 'WLAN-Venue-Name',
  185=> 'WLAN-Reason-Code',
  186=> 'WLAN-Pairwise-Cipher',
  187=> 'WLAN-Group-Cipher',
  188=> 'WLAN-AKM-Suite',
  189=> 'WLAN-Group-Mgmt-Cipher',
  190=> 'WLAN-RF-Band',
  # 191=> 'Unassigned',
  # 192=>-223 Experimental Use
  # 224=>-240 Implementation Specific
  241=> 'Extended-Attribute-1',
  # 241=>.1 Frag-Status
  # 241=>.2 Proxy-State-Length
  # 241=>.3 Response-Length
  # 241=>.4 Original-Packet-Code
  # 241=>.5 IP-Port-Limit-Info
  # 241=>.6 IP-Port-Range
  # 241=>.7 IP-Port-Forwarding-Map
  # 241=>.8 Operator-NAS-Identifier
  # 241=>.9 Softwire46-Configuration
  # 241=>.10  Softwire46-Priority
  # 241=>.11  Softwire46-Multicast
  # 241=>.{12-25} Unassigned
  # 241=>.26  Extended-Vendor-Specific-1
  # 241=>.{27-240}  Unassigned
  # 241=>.{241-255} Reserved
  242=> 'Extended-Attribute-2',
  # 242=>.{1-25}  Unassigned
  # 242=>.26  Extended-Vendor-Specific-2
  # 242=>.{27-240}  Unassigned
  # 242=>.{241-255} Reserved
  243=> 'Extended-Attribute-3',
  # 243=>.{1-25}  Unassigned
  # 243=>.26  Extended-Vendor-Specific-3
  # 243=>.{27-240}  Unassigned
  # 243=>.{241-255} Reserved
  244=> 'Extended-Attribute-4',
  # 244=>.{1-25}  Unassigned
  # 244=>.26  Extended-Vendor-Specific-4
  # 244=>.{27-240}  Unassigned
  # 244=>.{241-255} Reserved
  245=> 'Extended-Attribute-5',
  # 245=>.1 SAML-Assertion
  # 245=>.2 SAML-Protocol
  # 245=>.{3-25}  Unassigned
  # 245=>.26  Extended-Vendor-Specific-5
  # 245=>.{27-240}  Unassigned
  # 245=>.{241-255} Reserved
  246=> 'Extended-Attribute-6',
  # 246=>.{1-25}  Unassigned
  # 246=>.26  Extended-Vendor-Specific-6
  # 246=>.{27-240}  Unassigned
  # 246=>.{241-255} Reserved
  # 247=>-255 Reserved
}
RADIUS_ATTRIBUTE_TYPE_INVERT = RADIUS_ATTRIBUTE_TYPE.invert

VENDOR_IDS = {
  311=>"Microsoft"
}
VENDOR_IDS_INVERT = VENDOR_IDS.invert

VENDOR_SPECIFIC = {
  311=>{
    16=>'MS-MPPE-Send-Key',
    17=>'MS-MPPE-Recv-Key',
  }
}
VENDOR_SPECIFIC_INVERT = VENDOR_SPECIFIC.transform_values(&:invert)

# https://www.iana.org/assignments/eap-numbers/eap-numbers.xhtml#eap-numbers-1
EAP_PACKET_CODE = {
  1=>'Request',
  2=>'Response',
  3=>'Success',
  4=>'Failure',
  5=>'Initiate',
  6=>'Finish',
}
EAP_PACKET_CODE_INVERT = EAP_PACKET_CODE.invert

# https://www.iana.org/assignments/eap-numbers/eap-numbers.xhtml#eap-numbers-4
EAP_METHOD_TYPES = {
  # 0=>'Reserved',
  1=>'Identity',
  2=>'Notification',
  3=>'Legacy Nak',
  4=>'MD5-Challenge',
  5=>'One-Time Password (OTP)',
  6=>'Generic Token Card (GTC)',
  # 7=>'Allocated',
  # 8=>'Allocated',
  9=>'RSA Public Key Authentication',
  10=>'DSS Unilateral',
  11=>'KEA',
  12=>'KEA-VALIDATE',
  13=>'EAP-TLS',
  14=>'Defender Token (AXENT)',
  15=>'RSA Security SecurID EAP',
  16=>'Arcot Systems EAP',
  17=>'EAP-Cisco Wireless',
  18=>'GSM Subscriber Identity Modules (EAP-SIM)',
  19=>'SRP-SHA1',
  # 20=>'Unassigned',
  21=>'EAP-TTLS',
  22=>'Remote Access Service',
  23=>'EAP-AKA Authentication',
  24=>'EAP-3Com Wireless',
  25=>'PEAP',
  26=>'MS-EAP-Authentication',
  27=>'Mutual Authentication w/Key Exchange (MAKE)',
  28=>'CRYPTOCard',
  29=>'EAP-MSCHAP-V2',
  30=>'DynamID',
  31=>'Rob EAP',
  32=>'Protected One-Time Password',
  33=>'MS-Authentication-TLV',
  34=>'SentriNET',
  35=>'EAP-Actiontec Wireless',
  36=>'Cogent Systems Biometrics Authentication EAP',
  37=>'AirFortress EAP',
  38=>'EAP-HTTP Digest',
  39=>'SecureSuite EAP',
  40=>'DeviceConnect EAP',
  41=>'EAP-SPEKE',
  42=>'EAP-MOBAC',
  43=>'EAP-FAST',
  44=>'ZoneLabs EAP (ZLXEAP)',
  45=>'EAP-Link',
  46=>'EAP-PAX',
  47=>'EAP-PSK',
  48=>'EAP-SAKE',
  49=>'EAP-IKEv2',
  50=>'EAP-AKA\'',
  51=>'EAP-GPSK',
  52=>'EAP-pwd',
  53=>'EAP-EKE Version 1',
  54=>'EAP Method Type for PT-EAP',
  55=>'TEAP',
  56=>'EAP-NOOB',
  #=> 57-191'  Unassigned',
  #=> 192-253' Unassigned',
  # 254=>'Reserved for the Expanded Type',
  # 255=>'Experimental',
  #=> 256-4294967295'  Unassigned',
}
EAP_METHOD_TYPES_INVERT = EAP_METHOD_TYPES.invert

def eap_parse(pkt)
  # https://datatracker.ietf.org/doc/html/rfc2284#section-2.2
  package_type = EAP_PACKET_CODE.fetch(pkt.read(1).unpack1('C')) rescue (raise 'unknown eap package type')
  identifier = pkt.read(1).unpack1('C')
  length = pkt.read(2).unpack1('S>')
  raise 'length not in 4 and 4096' unless (4..4096).include?(length)
  method = nil
  data = nil
  if %w(Request Response).include?(package_type)
    if length - 4 > 0
      method = EAP_METHOD_TYPES.fetch(pkt.read(1).unpack1('C')) rescue (raise 'unknown eap method')
      if method == 'EAP-TTLS'
        data = {}
        flags = pkt.read(1).unpack1('C')
        data['Length included'] = flags & (2<<6) != 0
        data['More Fragments'] = flags & (2<<5) != 0
        data['Start'] = flags & (2<<4) != 0
        data['Version'] = flags & 7
        puts "version nicht 0" unless data['Version'] == 0
        if data['Length included']
          data['message length'] = pkt.read(4).unpack1('L>')
        end
        data['data'] = pkt.read()
      else
        data = pkt.read()
      end
    else
      raise 'hmm expected some eap method here'
    end
  end
  return {type: package_type, id: identifier, method: method, data: data}
end

def eap_response_single(type, id, method=nil, data=nil)
  return [EAP_PACKET_CODE_INVERT.fetch(type, type), id, 4].pack('CCS>').b if not method
  return [EAP_PACKET_CODE_INVERT.fetch(type, type), id, 5, EAP_METHOD_TYPES_INVERT.fetch(method, method)].pack('CCS>C').b if not data
  return [EAP_PACKET_CODE_INVERT.fetch(type, type), id, 5+data.size, EAP_METHOD_TYPES_INVERT.fetch(method, method), data].pack('CCS>Ca*').b
end
def eap_response(type, id, method=nil, data=nil, **fields)
  ret = eap_response_single(type, id, method, eap_ttls_data_encode(data, data&.b&.size))
  return ret.each_char.each_slice(253).map(&:join) if ret.length > 253
  return [ret]
end

def eap_ttls_data_encode(data=nil, message_len=nil, **fields)
  return nil if data.nil? || data.size == 0
  fields.default = '0'
  fields['Length included'] = '1' unless message_len.nil?
  out = [fields.values_at('Length included', 'More Fragments', 'Start', 'r1','r2').join() + '000'].pack('B*')
  out += [message_len].pack('L>') if fields['Length included'] == '1'
  data.nil? ? out.b : (out + data).b
end

def eap_ttls_avp_parse(pkt)
  attrs = {}
  until pkt.eof?
    old_pos = pkt.pos
    if pkt.read().tr("\0", '') == ''
      break
    else
      pkt.pos = old_pos
    end
    code = pkt.read(4).unpack1('L>')
    code = RADIUS_ATTRIBUTE_TYPE.fetch(code, nil) if code <= 256
    flags = pkt.read(1).unpack1('C')
    raise 'Unknown attribute' if (flags & 64) != 0 && code.nil?
    length = ("\x00" + pkt.read(3)).unpack1('L>') - 8
    if (flags & 128) != 0
      vendor = pkt.read(4).unpack1('L>')
      length -= 4
    end
    data = pkt.read(length)
    data = data.b.sub(/\0+$/, '') if code == 'User-Password'
    attrs[code] ||= []
    attrs[code] << data
  end
  attrs
end

def radius_parse(pkt)
  package_type = RADIUS_PACKET_CODE.fetch(pkt.read(1).unpack1('C')) rescue (raise 'unknown radius package type')
  identifier = pkt.read(1).unpack1('C')
  length = pkt.read(2).unpack1('S>')
  raise 'length not in 20 and 4096' unless (20..4096).include?(length)
  authenticator = pkt.read(16)
  attrs = StringIO.new(pkt.read(length - 20)) rescue StringIO.new('')
  attrs.binmode
  attributes = {}
  while not attrs.eof?
    begin
      attr_type = RADIUS_ATTRIBUTE_TYPE.fetch(attrs.read(1).unpack1('C'))
      attr_length = attrs.read(1).unpack1('C')
      attr_value = attrs.read(attr_length-2)
      attributes[attr_type] ||= []
      attributes[attr_type] <<
        if attr_type == 'EAP-Message'
          eap_parse(StringIO.new(attr_value).binmode)
        else
          attr_value
        end
    rescue KeyError
      puts 'ignoring attribute'
      attrs.read(attrs.read(1).unpack1('C')-2) # throw away the data
    end
  end
  return {type: package_type, id: identifier, auth: authenticator, attributes: attributes}
end

def radius_message_auth(type, id, length, authenticator, attrs)
  # this is a function for potentially verifying such codes of clients
  OpenSSL::HMAC.digest("MD5", SECRET, [
    type,
    id,
    length,
    authenticator,
    attrs + [RADIUS_ATTRIBUTE_TYPE_INVERT['Message-Authenticator'], 18,''].pack('CCa16')
  ].pack('CCS>a16A*'))
end

class String
  def xor(other)
    self.each_byte.zip(other.each_byte).map{|a,b|(a^b).chr}.join('')
  end
end

def microsoft_md5_cipher(secret,salt,plaintext,decrypt=false)
  b = OpenSSL::Digest::MD5.digest(secret + salt)
  plaintext.b.split('').each_slice(8).map do |plain|
    c = plain.join().ljust(8,"\0").xor(b)
    b = OpenSSL::Digest::MD5.digest(secret + (decrypt ? plain.join() : c))
    c
  end.join()
end

def radius_response_vendor_value(vendor, attributes)
  [id = VENDOR_IDS_INVERT.fetch(vendor, vendor), attributes.map do |t,vals|
    vals.map{|v|[VENDOR_SPECIFIC_INVERT.fetch(id).fetch(t,t), v.length+2, v].pack('CCA*')}.join('')
  end.join('')].pack('L>A*')
end

def radius_response(code, request, attributes={})
  code = RADIUS_PACKET_CODE_INVERT.fetch(code, code)
  attrs = attributes.map{|t,vals| vals.map{|v| raise "toolong #{v.length}" if v.length >=254;[RADIUS_ATTRIBUTE_TYPE_INVERT.fetch(t,t), v.length+2, v].pack('CCA*')}.join('')}.join('').b
  length = 20 + attrs.length
  raise 'too long' if length > 4096
  if attributes['EAP-Message']
    # see RFC 3579
    length += 18
    mauth = radius_message_auth(
      code, request[:id], length, request[:auth],
      attrs
    )
    attrs << [RADIUS_ATTRIBUTE_TYPE_INVERT['Message-Authenticator'], 18, mauth].pack('CCa16')
  end
  authenticator = OpenSSL::Digest::MD5.digest(
    [
      code,
      request[:id],
      length,
      request[:auth],
      attrs,
      SECRET
    ].pack('CCS>a16A*A*')
  )
  [
    code,
    request[:id],
    length,
    authenticator,
    attrs
  ].pack('CCS>a16A*')
end

tls_connections = {}
tls_context = OpenSSL::SSL::SSLContext.new
unless File.exists?('./server.crt')
  puts 'generating key ;)'
  `openssl req -nodes -x509 -newkey rsa:4096 -sha256 -subj '/CN=localhost/' -days 99999 -keyout server.key -out server.crt`
end
tls_context.add_certificate(
  OpenSSL::X509::Certificate.new(File.read('./server.crt')),
  OpenSSL::PKey::RSA.new(        File.read('./server.key'))
)
tls_context.min_version = OpenSSL::SSL::TLS1_2_VERSION
tls_context.max_version = OpenSSL::SSL::TLS1_3_VERSION
# tls_context.enable_fallback_scsv
tls_context.ciphers = 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384'

# hack because you got no patch yet :P
unless OpenSSL::SSL::SSLSocket.instance_methods.include?(:export_keying_material)
  class OpenSSL::SSL::SSLSocket
    def export_keying_material(label, len, context=nil)
      return 'x'*len
    end
  end
end

Socket.udp_server_loop('localhost', 1812) do |msg, client|
  # p msg, client
  puts '------------------------------------------------ New Packet, new thing?'
  case request = p(radius_parse(StringIO.new(msg).binmode))
  in {type: 'Access-Request'}
    if eap = request[:attributes]['EAP-Message']
      # puts "! got EAP message trying to respond"
      eap = eap.first
      if eap[:method] == 'EAP-TTLS'
        unless tls_connections['a']
          puts "JAAAAAAAAA"
          tunnel_socket, plain_socket = UNIXSocket.pair
          tls_socket = OpenSSL::SSL::SSLSocket.new(tunnel_socket, tls_context)
          tls_socket.sync_close = true
          tls_connections['a'] = [tls_socket, plain_socket, [], nil]
          if eap[:data]
            puts '! trying to do the tls stuff'
            plain_socket.send(eap[:data]['data'], 0)
            thing = (tls_socket.accept_nonblock rescue '')
            # p("----",thing,"----")
            response = plain_socket.recv(99999)
            p tls_socket.state
            # p("----",response,"----"+ response.size.to_s)
            puts '! got a response internally!'

            tls_connections['a'][2] = response.b.each_char.each_slice(1450).map(&:join)
            client.reply(radius_response('Access-Challenge', request, {'EAP-Message'=>eap_response('Request', eap[:id]+1, 'EAP-TTLS', tls_connections['a'][2].shift)}))
          end
        else
          puts "TLS GOGOGO"
          tls_socket, plain_socket, messages, socket = tls_connections['a']
          plain_socket.send(eap[:data]['data'], 0)
          if messages.any?
            client.reply(radius_response('Access-Challenge', request, {'EAP-Message'=>eap_response('Request', eap[:id]+1, 'EAP-TTLS', tls_connections['a'][2].shift)}))
            # client.reply(radius_response('Access-Challenge', request, {'EAP-Message'=>[tls_connections['a'][2].shift]}))
            next
          end
          if true
            if socket.nil?
              socket = (tls_socket.accept_nonblock rescue nil)
              tls_connections['a'][3] = socket
            end
            tls_query = socket.read_nonblock(99999) rescue nil if socket
            if tls_query
              # p("--tls_query--",tls_query,"--tls_query--")
              avp = eap_ttls_avp_parse(StringIO.new(tls_query).binmode)
              p(avp)
              if avp['User-Password'] && avp['User-Name'] # PAP
                p('! PAP')
                # vvvvvvvvvvvvvvvv worst possible implementation vvvvvvvvvvvvvvvv
                ok = USERS[avp['User-Name'].first] == avp['User-Password'].first
                # ^^^^^^^^^^^^^^^^ worst possible implementation ^^^^^^^^^^^^^^^^
                if ok
                  p('! sent ok')
                  #todo:: https://datatracker.ietf.org/doc/html/rfc5281#section-8
                  # p(OpenSSLThing.client_random(socket))
                  # p(socket.export_keying_material("server finished"))
                  # p(socket.export_keying_material("client finished"))
                  challenge = socket.export_keying_material("ttls keying material", 64).b
                  msk = challenge[...32]
                  emsk = challenge[32...]
                  # p(OpenSSLThing.server_random(socket))
                  # p(OpenSSLThing.master_key(socket.session))
                  s1 = (2**7).chr + "a"
                  s2 = (2**7).chr + "b"
                  # p(socket.session.to_text.each_line.grep(/Master-Key/).first.split(': ').last.strip)
                  p request[:auth]
                  keyshare = [
                    radius_response_vendor_value("Microsoft", {"MS-MPPE-Recv-Key"=>[s1+s1 + microsoft_md5_cipher(SECRET,request[:auth]+s1, msk[...16])]}),
                    radius_response_vendor_value("Microsoft", {"MS-MPPE-Send-Key"=>[s2+s1 + microsoft_md5_cipher(SECRET,request[:auth]+s2, msk[16...])]})
                  ]
                  client.reply(r = radius_response('Access-Accept', request, {'EAP-Message'=>eap_response('Success', eap[:id]+1, 'EAP-TTLS'), 'Vendor-Specific'=>keyshare}))
                  p(radius_parse(StringIO.new(r).binmode))
                else
                  p('! sent nok')
                  client.reply(radius_response('Access-Reject', request, {'EAP-Message'=>eap_response('Failure', eap[:id]+1, 'EAP-TTLS')}))
                end
                p('! killing connection')
                tls_connections.delete('a')
              elsif avp['EAP-Message'] # EAP goes even deeper here
                p('! not implemented for now')
              else
                p('! unknown auth here!')
              end
              next # ignore the stuff below
            end
            response = plain_socket.recv_nonblock(99999) rescue ''
            # p("----",response,"----")
            puts '! got a response internally? 2'
            client.reply(radius_response('Access-Challenge', request, {'EAP-Message'=>eap_response('Request', eap[:id]+1, 'EAP-TTLS', response)}))
          end
        end
      else
        puts "! not TTLS, trying to get the client to start TTLS"
        client.reply(radius_response('Access-Challenge', request, {'EAP-Message'=>[eap_response_single('Request', eap[:id]+1, 'EAP-TTLS', eap_ttls_data_encode('Start'=>'1'))]}))
      end
    else # reject
      puts "! rejected client"
      client.reply(radius_response('Access-Reject', request))
    end
  else
    puts "! did not got an Access-Request, not answering"
  end
end
