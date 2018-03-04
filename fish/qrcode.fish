# needs qrencode installed: http://megaui.net/fukuchi/works/qrencode/index.en.html
# also feh
function qrcode
	qrencode -s 10 $argv -o - | timeout 15 feh --zoom fill  - &
end
