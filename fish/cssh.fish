function cssh
	# cluster ssh implementation with kitty and fish
	set -lx servers $argv
	kitty --override allow_remote_control=yes fish -C 'for s in (string split " " $servers); kitty @ new-window --keep-focus --no-response --title ssh fish -C "set -x TERM xterm; ssh $s"; end; kitty @ goto-layout grid; echo --- Control all here --- ; kitty @ send-text --match title:ssh --stdin' &; disown
end
