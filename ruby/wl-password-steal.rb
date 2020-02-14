# this program waits for a password in the clipboard and prints it
def test_mimetypes
  [
    `wl-paste --list-types          `.include?('x-kde-passwordManagerHint') ? '' : nil,
    `wl-paste --list-types --primary`.include?('x-kde-passwordManagerHint') ? '--primary' : nil,
  ]
end

sleep 0.4 until (m = test_mimetypes).any?
m.compact.each{|arg| puts 'got you:', `wl-paste #{arg}`}
