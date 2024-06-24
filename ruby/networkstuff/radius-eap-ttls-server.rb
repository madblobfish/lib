require_relative 'radius.rb'
require 'openssl'
require 'socket'
require 'stringio'

SECRET = 'radsec'
USERS = {'user'=>'password'}
DEBUG = ARGV.include?('--debug')

tls_connections = {}
tls_context = OpenSSL::SSL::SSLContext.new
unless File.exist?('./server.crt')
  puts 'generating key'
  `openssl req -nodes -x509 -newkey rsa:4096 -sha256 -subj '/CN=localhost/' -days 99999 -keyout server.key -out server.crt`
end
tls_context.add_certificate(
  OpenSSL::X509::Certificate.new(File.read('./server.crt')),
  OpenSSL::PKey::RSA.new(        File.read('./server.key'))
)
tls_context.min_version = OpenSSL::SSL::TLS1_2_VERSION
tls_context.max_version = OpenSSL::SSL::TLS1_3_VERSION
# tls_context.enable_fallback_scsv
tls_context.ciphers = 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305'

# hack because you got no patch yet :P
unless OpenSSL::SSL::SSLSocket.instance_methods.include?(:export_keying_material)
  class OpenSSL::SSL::SSLSocket
    def export_keying_material(label, len, context=nil)
      raise 'install or wait for https://github.com/ruby/openssl/pull/530'
    end
  end
end

Socket.udp_server_loop(1812) do |msg, client|
  request = radius_parse(StringIO.new(msg).binmode)
  if DEBUG
    puts '------------------------------------------------ New RADIUS Packet'
    p request
  end
  case request
  in {type: 'Access-Request'}
    if eap = request[:attributes]['EAP-Message']
      # puts "! got EAP message trying to respond"
      eap = eap.first
      if eap[:method] == 'EAP-TTLS'
        unless tls_connections['a']
          puts "! starting TLS inside of EAP connection"
          tunnel_socket, plain_socket = UNIXSocket.pair
          tls_socket = OpenSSL::SSL::SSLSocket.new(tunnel_socket, tls_context)
          tls_socket.sync_close = true
          tls_connections['a'] = [tls_socket, plain_socket, [], nil]
          if eap[:data]
            # puts '! trying to do the tls stuff'
            plain_socket.send(eap[:data]['data'], 0)
            thing = (tls_socket.accept_nonblock rescue '')
            # p("--thing--",thing,"--thing--")
            response = plain_socket.recv(99999)
            # p tls_socket.state
            # p("----",response,"----"+ response.size.to_s)
            # puts '! got a response internally!'

            tls_connections['a'][2] = response.b.each_char.each_slice(1450).map(&:join)
            client.reply(radius_response(SECRET, 'Access-Challenge', request, {'EAP-Message'=>eap_response('Request', eap[:id]+1, 'EAP-TTLS', tls_connections['a'][2].shift)}))
          end
        else
          tls_socket, plain_socket, messages, socket = tls_connections['a']
          if socket.nil?
            socket = (tls_socket.accept_nonblock rescue nil)
            tls_connections['a'][3] = socket
          end
          plain_socket.send(eap[:data]['data'], 0)
          response = plain_socket.recv_nonblock(99999) rescue ''
          if response != ''
            tls_connections['a'][2] = response.b.each_char.each_slice(1450).map(&:join)
            messages = [true]
          end
          if messages.any?
            puts '! send TLS data until we finished sending a TLS message'
            client.reply(radius_response(SECRET, 'Access-Challenge', request, {'EAP-Message'=>eap_response('Request', eap[:id]+1, 'EAP-TTLS', tls_connections['a'][2].shift)}))
            next
          end
          tls_query = socket.read_nonblock(99999) rescue nil
          if tls_query
            puts '--------------------- New TTLS encapsulated EAP Packet'
            # p("--tls_query--",tls_query,"--tls_query--")
            avp = eap_ttls_avp_parse(StringIO.new(tls_query).binmode)
            p(avp) if DEBUG
            if avp['User-Password'] && avp['User-Name'] # PAP
              puts '! doing EAP-PAP authentication path'
              # vvvvvvvvvvvvvvvv worst possible implementation vvvvvvvvvvvvvvvv
              ok = USERS[avp['User-Name'].first] == avp['User-Password'].first
              # ^^^^^^^^^^^^^^^^ worst possible implementation ^^^^^^^^^^^^^^^^
              if ok
                puts '! sent ok'
                # https://datatracker.ietf.org/doc/html/rfc5705
                msk = socket.export_keying_material("ttls keying material", 64).b
                keyshare = [
                  [msk[...32], (2**7).chr + "a"],
                  [msk[32...], (2**7).chr + "b"]
                ].map do |msk, s|
                  radius_response_vendor_value('Microsoft', {"MS-MPPE-Recv-Key"=>[s + microsoft_md5_cipher(SECRET, request[:auth]+s, [32].pack('C')+msk)]})
                end
                client.reply(r = radius_response(SECRET, 'Access-Accept', request, {'EAP-Message'=>eap_response('Success', eap[:id]+1, 'EAP-TTLS'), 'Vendor-Specific'=>keyshare}))
                p(radius_parse(StringIO.new(r).binmode)) if DEBUG
              else
                puts '! sent nok'
                client.reply(radius_response(SECRET, 'Access-Reject', request, {'EAP-Message'=>eap_response('Failure', eap[:id]+1, 'EAP-TTLS')}))
              end
              puts '! killing connection, done'
              tls_connections.delete('a')
            elsif avp['EAP-Message'] # EAP goes even deeper here
              puts '! not implemented for now'
              client.reply(radius_response(SECRET, 'Access-Reject', request))
            else
              puts '! unknown auth here!'
              client.reply(radius_response(SECRET, 'Access-Reject', request))
            end
            next # ignore the stuff below
          end
          response = plain_socket.recv_nonblock(99999) rescue ''
          raise 'TLS response should be empty here, we expect data' if response != ''
          puts '! sending empty TLS data to get responses'
          client.reply(radius_response(SECRET, 'Access-Challenge', request, {'EAP-Message'=>eap_response('Request', eap[:id]+1, 'EAP-TTLS', '')}))
        end
      else
        puts "! not TTLS, trying to get the client to start TTLS"
        client.reply(radius_response(SECRET, 'Access-Challenge', request, {'EAP-Message'=>[eap_response_single('Request', eap[:id]+1, 'EAP-TTLS', eap_ttls_data_encode('Start'=>'1'))]}))
      end
    else # reject
      puts "! rejected client"
      client.reply(radius_response(SECRET, 'Access-Reject', request))
    end
  else
    puts "! did not got an Access-Request, not answering"
  end
end
