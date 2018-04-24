function gh-ver
	# gets the latest version number from github
	curl -s "https://github.com/"$argv"/releases/latest" | sed -re 's/^.+\/releases\/tag\/([^/]+)".+$/\1/'
end
