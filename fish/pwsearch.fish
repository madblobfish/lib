function pwsearch
	set pw (echo -n $argv | sha1sum | grep -Eo '^(\w|\d)+')
	curl -s https://api.pwnedpasswords.com/range/(string sub -l 5 $pw) | grep -i (string sub -s 6 $pw)
end
