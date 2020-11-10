require 'socket'
require 'weakref'

STO = {}
Socket.udp_server_loop(1235){|msg, msg_src|
  if STO.has_key? msg
    msg_src.reply(STO[msg].first.map(&:to_s).join("\t"))
    STO[msg].last.reply(
      [
        msg_src.remote_address.ip_address,
        msg_src.remote_address.ip_port
      ].map(&:to_s).join("\t")
    )
  else
    STO[msg] = WeakRef.new([[
      Time.now, msg_src.remote_address.ip_address,
      msg_src.remote_address.ip_port
    ], msg_src])
    msg_src.reply("first")
  end
}
