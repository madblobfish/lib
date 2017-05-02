#include <stdlib.h>
#include <stdio.h> // printf() n stuff
#include <math.h> //for sqrt()
#include <time.h> //for clock() and CLK_TCK
#include <string.h> //for strncmp() and strtol
#include <stdbool.h> //for bool datatypes
#include <omp.h> //paralell shits

#define put(a){fputs(a, stdout);}

// fastest times
// 7.051(10mio) / 216.590(100mio)

int main(int argc, char const *argv[]){ // args do not work if you disable the cstdlib
	unsigned int t;
	unsigned int length = 10000000;
	bool calc = true;
	bool print = true;
	static bool *storage;

	unsigned int i;
	unsigned int max;
	unsigned int at = 1;
	bool prime;

	if(argc<2){
		puts("see --help for information");
	}
	for(i = 1; i < argc; ++i){
		if(argc < 2 || !strncmp(argv[i], "-h", 2) || !strncmp(argv[1],"--help", 6)){
			put( "Usage: ");put(argv[0]);puts(" [options] <maximum primes>");
			puts( "  -h               Display this Help" );
			puts( " --help            Display this Help\n" );

			puts( "  -v               Display Version" );
			puts( " --version         Display Version\n" );

			puts( "  -t               Insert Calculation Time in Output" );
			puts( "  -T               Only output the Calculation Time\n" );

			puts( "Copyright Information:" );
			puts( "Use as you like, it's yours" );
			puts( "No Warranties and Limitation of Liability" );
			return 0;
		}else if(!strncmp(argv[1], "-v", 2) || !strncmp(argv[1], "--version", 9)){
			puts( "Version 0.1.5 of PrimeSieve" );
			puts( "Written By Killerwolf" );
			return 0;
		}else if(!strncmp(argv[i], "-t", 2)){
			calc = true;
		}else if(!strncmp(argv[i], "-T", 2)){
			print = false;
			calc = true;
		}else if(strtol(&argv[i][0], NULL, 10)){
			length = strtol(&argv[i][0], NULL, 10) + 1;
			break;
		};
	};

	t = clock();

	// initialize the storrage
	storage = (bool*) malloc( sizeof(storage) * length );
	storage[0] = 1;

	// prime loop
	#pragma omp parallel
	while(length > at){
		at += 2;
		max = (int) sqrt(at);
		i = 0;
		prime = true;
		storage[(at-1)/2] = 0;
		while(i < max){
			i++;
			if(storage[i] == 1 && (at%((i*2)+1)) == 0){
				prime = false;
				break;
			};
		};
		if(prime){
			storage[(at-1)/2] = 1;
		};
	};

	if(print){
		put( "[2" );
		length /= 2;
		length -= 1;
		i = 0;
		while(length > i){
			i++;
			if(storage[i] == 1){
				printf( ", %d", ((i*2)+1) );
			};
		};
		put( "]\n" );
	}

	free(storage);
	if(calc){
		t = clock() - t;
		printf( "Calctime: %d clicks (%.5f seconds)", t , ( (double)t / (double)CLOCKS_PER_SEC ) );
	};
	return 0;
}

/*

gcc
 -s
 -faggressive-loop-optimizations
 -fno-bounds-check
 -nostartfiles
 -fdelete-null-pointer-checks
 -fdelete-dead-exceptions
 -fno-exceptions
 -ffast-math
 -ffinite-math-only
 -fmove-loop-invariants
 -freorder-blocks-and-partition
 -freorder-functions
 -fsigned-zeros
 -fsignaling-nans
 -fstrict-overflow
 -fstrict-aliasing
 -funsafe-math-optimizations
 -funsafe-loop-optimizations
 -funroll-all-loops
 -fassociative-math
 -fwrapv
 -gtoggle
 -fno-asynchronous-unwind-tables
 -falign-functions=0
 -falign-jumps=0
 -falign-labels=0
 -falign-loops=0
 -O3
 -Ofast
 primecalc.c
 -o a.exe -Wall

strip
objdump
*/