import itertools
import sys
from ykman import device
from yubikit.core.otp import OtpConnection, CommandRejectedError
from yubikit.support import get_name, read_info
from yubikit.yubiotp import YubiOtpSession, SLOT, UpdateConfiguration

def guesstimator():
	for guess in itertools.product(b'abcdefghijklmnopqrstuvwxyz0123456789', repeat=6):
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

if not session.get_config_state().is_configured(1):
	raise Exception('nothing configured')
for guess in guesstimator():
	try:
		session.delete_slot(
			1,
			bytes(guess)
		)
		print("\rgot it", guess)
		break
	except CommandRejectedError as e:
		if str(e) != 'No data':
			raise e
		print("\rdid not work {}".format(guess), end='')
