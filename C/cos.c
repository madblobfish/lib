#include <stdio.h>
#include <stdlib.h>

double coss(double __X){
	__asm__(
		"fcos"
		: "=t" (__X)
		: "0" (__X)
	);
	return __X;
}

int main(int argc, char const *argv[]){
	if(argc == 2){
		double in = atof(argv[1]);
		printf("in : %4.8f\n", in);
		printf("out: %4.8f\n", coss(in));
	}else{
		puts("give me one float input!");
		if(argc != 1){return 1;}
	}
	return 0;
}
