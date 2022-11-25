function cssh
	# cluster ssh implementation with kitty and fish
	set -lx servers $argv
	kitty --title 'cssh '$servers --override allow_remote_control=yes fish -c 'kitty @ goto-layout grid; for s in (string split " " $servers); kitty @ new-window --keep-focus --no-response --title ssh fish -C "set s $s; ssh $s"; end; kitty +kitten broadcast' &; disown
end
