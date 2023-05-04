function gh-ver
	# gets the latest version number from github
	curl -s "https://github.com/"$argv"/releases/latest" -I | sed -nre '/location/s/.*\///p'
end
