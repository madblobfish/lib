# needs qrencode installed: http://megaui.net/fukuchi/works/qrencode/index.en.html
# also feh
function qrcode
	qrencode $argv -o - | timeout 10 feh - &
end
