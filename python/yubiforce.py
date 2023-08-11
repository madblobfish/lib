import itertools
import sys
from ykman import device
from yubikit.core.otp import OtpConnection, CommandRejectedError
from yubikit.support import get_name, read_info
from yubikit.yubiotp import YubiOtpSession, SLOT, UpdateConfiguration

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

CHARSET = b'abcdefghijklmnopqrstuvwxyz0123456789'
def guesstimator():
	for guess in itertools.product(CHARSET, repeat=6):
		yield bytes(guess)

iterator = guesstimator()
try:
	previous = tuple(bytes.fromhex(sys.argv[2]))
	skip = sum(map(lambda x: tuple(CHARSET).index(x[1]) * len(CHARSET)**(5-x[0]), enumerate(previous)))
	iterator = itertools.islice(iterator, skip, None)
	print("Note: preemptied {}", skip)
except IndexError:
	pass

try:
	for guess in iterator:
		try:
			session.delete_slot(1, guess)
			print("\rgot it", guess.hex())
			break
		except CommandRejectedError as e:
			if str(e) != 'No data':
				raise e
except KeyboardInterrupt:
	print("got until {}".format(guess.hex()), end='')
