
build:
	gcc -s -Ofast -lgmp bitprime.c -o bitprime -Wall
	gcc -s -Ofast -fopenmp primecalc.c -o primecalc -Wall
	gcc -s -Ofast logprime.c -o logprime -Wall
