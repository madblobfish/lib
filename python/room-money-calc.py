EURO_BILL_SIZE = {
	5: 120*62,
	10: 127*67,
	20: 133*72,
	50: 140*77,
	100: 147*82,
	200: 153*82,
	500: 160*82,
}

def how_much_money_fits_mah_room(euro, room_area, room_height=2.35):
	return room_area*room_height / (EURO_BILL_SIZE[euro]*12/1e9) * 100 * euro

def how_much_money_fits_mah_room_all_bills(room_area, room_height=2.35):
	return {x: how_much_money_fits_mah_room(x, room_area, room_height) for x in EURO_BILL_SIZE}

import sys
if __file__ == sys.argv[0]:

	if len(sys.argv) == 4:
		print(how_much_money_fits_mah_room(int(sys.argv[3]), float(sys.argv[1]), float(sys.argv[2])))
	elif len(sys.argv) == 3:
		print(how_much_money_fits_mah_room_all_bills(float(sys.argv[1]), float(sys.argv[2])))
	elif len(sys.argv) == 2:
		print(how_much_money_fits_mah_room_all_bills(float(sys.argv[1])))
	else:
		print(__file__ + " <room_area in m²> [<room_height in m default 2.35> [<euro_bill default all>]]\n")
		print("This program calculates the amount of money you could put into your room.")
		exit(1)
	exit(0)
