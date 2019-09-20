#!/usr/bin/python

import zlib
import sys

if len(sys.argv) >= 2:
	i = open(sys.argv[1], "rb").read()
else:
	i = sys.stdin.buffer.read()

b = zlib.decompress(i)

if len(sys.argv) >= 3:
	f = open(sys.argv[2],"wb")
	f.write(b)
else:
	sys.stdout.buffer.write(b)

