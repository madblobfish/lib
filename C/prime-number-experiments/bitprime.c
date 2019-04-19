#include <stdlib.h>
#include <stdio.h> // printf() n stuff
#include <math.h> //for sqrt()
#include <time.h> //for clock() and CLK_TCK
#include <string.h> //for strncmp() and strtol
#include "gmp.h" //for numberz

// meine schnellsten zeiten
// 2.764(10mio) / 121.405(100mio)

unsigned int isqrt(unsigned int num){
	unsigned int res = 0;
	unsigned int bit = 1 << 31; // The second-to-top bit is set: 1 << 30 for 32 bits

	// "bit" starts at the highest power of four <= the argument.
	while(bit > num){
		bit >>= 2;
	}

	while(bit != 0){
		if(num >= res + bit){
			num -= res + bit;
			res = (res >> 1) + bit;
		}else{
			res >>= 1;
		}
		bit >>= 2;
	}
	return res;
}

int main(int argc, char const *argv[]){
	mpz_t primes;
	mpz_t pattern;
	mpz_t one;
	mpz_t two;

	unsigned int t;
	char calc = 0;
	char print = 1;
	char getnum = 0;

	unsigned int length = 1000;
	unsigned int i;
	unsigned int max;

	for(i = 1; i < argc; ++i){
		if(argc < 2 || !strcmp(argv[i], "-h") || !strcmp(argv[1], "--help")){
			printf("Usage: %s ", argv[0]);
			puts("[options] <maximum primes>\n" );
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
		}else if(!strcmp(argv[1], "-v") || !strcmp(argv[1], "--version")){
			puts( "Version 0.0.1 of BitPrimeSieve\nWritten By Killerwolf" );
			return 0;
		}else if(!strcmp(argv[i], "-t")){
			calc = 1;
		}else if(!strcmp(argv[i], "-n")){
			getnum = 1;
		}else if(!strcmp(argv[i], "-T")){
			getnum = 0;
			print = 0;
			calc = 1;
		}else if(strtol(&argv[i][0], NULL, 10)){
			length = strtol(&argv[i][0], NULL, 10) + 1;
			break;
		};
	};

	length /= 2;

	mpz_init(primes);
	mpz_init(pattern);
	mpz_init(one);
	mpz_init(two);

	max = isqrt(length);
	t = clock();
	i = 0;

	while(i++ < max){
		if(!mpz_tstbit(primes, length-i)){
			mpz_ui_pow_ui(one, 2, length-i);	// x = 2^(l-1)

			mpz_ui_pow_ui(two, 2, (i*2)+1);	// y = 2^(i*2+1)-1
			mpz_sub_ui(two, two, 1);

			mpz_fdiv_q(pattern, one, two);	// z = x / y

			mpz_ior(primes, primes, pattern);	// primes = primes XOR z
		}
	}

	t = clock() - t;

	if(print){
		i=length;
		printf("[2");
		while(--i > 0){
			if(!mpz_tstbit(primes, i)){
				printf(", %d", 2*(length-i)+1);
			}
		}
		printf("]\n");
	}

	if(getnum){
		puts(mpz_get_str(NULL, 2, primes));
	}

	mpz_clear(primes);
	mpz_clear(pattern);
	mpz_clear(one);
	mpz_clear(two);

	if(calc){
		printf( "Calctime: %d clicks (%.5f seconds)\n", t/10000 , ( (double)t / (double)CLOCKS_PER_SEC ) );
	};
	return 0;
}
