function inode
	stat $argv | grep Inode: | sed -re 's/.*Inode: ([0-9]+) .*/\1/'
end
