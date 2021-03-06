require 'socket'
require 'weakref'

STORAGE = {}
Socket.udp_server_loop(1235){|msg, msg_src|
  if STORAGE.has_key? msg
    msg_src.reply(STORAGE[msg].first.map(&:to_s).join("\t"))
    other = STORAGE[msg].last
    other.reply(
      [
        msg_src.remote_address.ip_address,
        msg_src.remote_address.ip_port
      ].map(&:to_s).join("\t")
    )
    STORAGE.delete(msg)
#    other.close()
#    msg_src.close()
  else
    STORAGE[msg] = WeakRef.new([[
      Time.now.to_i, msg_src.remote_address.ip_address,
      msg_src.remote_address.ip_port
    ], msg_src])
    msg_src.reply("first")
  end
}
