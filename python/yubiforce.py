import itertools
import sys
from ykman import device
from yubikit.core.otp import OtpConnection, CommandRejectedError
from yubikit.yubiotp import YubiOtpSession, SLOT, UpdateConfiguration

def guesstimator():
	for guess in itertools.combinations_with_replacement(b'abcdefghijklmnopqrstuvwxyz0123456789', 6):
		yield guess

def get_device(serial):
	devs = device.list_all_devices()
	for dev, nfo in devs:
		if nfo.serial == int(serial):
			return dev, nfo

dev, nfo = get_device(sys.argv[1])

if not dev.supports_connection(OtpConnection):
	raise "AAAHHHH MY OTP"
conn = dev.open_connection(OtpConnection)
session = YubiOtpSession(conn)

for guess in guesstimator():
	try:
		session.update_configuration(
			SLOT(1),
			UpdateConfiguration().append_cr(True).use_numeric(True).pacing(False, False),
			None,
			bytes(guess)
		)
		print(guess)
		raise "the end :)"
	except CommandRejectedError:
		print("\rdid not work {}".format(guess), end='')
