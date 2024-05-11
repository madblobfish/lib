# needs qrencode installed: http://megaui.net/fukuchi/works/qrencode/index.en.html
# also feh
function qrcode
	qrencode -t UTF8 -- $argv
end
