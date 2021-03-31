#include <stdio.h>
#include <stdlib.h>

// __attribute__((always_inline))
/*inline*/ double _cos(double __X){
	__asm__(
		"fcos"
		: "=t" (__X)
		: "0" (__X)
	);
	return __X;
}

// __attribute__((always_inline))
/*inline*/ double _sin(double __X){
	__asm__(
		"fsin"
		: "=t" (__X)
		: "0" (__X)
	);
	return __X;
}

// __attribute__((always_inline))
/*inline*/ double _sincos_c(double __X){
	double Y;
	__asm__(
		"fsincos"
		: "=t" (__X), "=u" (Y)
		: "0" (__X)
	);
	return __X;
}
// __attribute__((always_inline))
/*inline*/ double _sincos_s(double __X){
	double Y;
	__asm__(
		"fsincos"
		: "=t" (Y), "=u" (__X)
		: "0" (__X)
	);
	return __X;
}

// __attribute__((always_inline))
/*inline*/ double _sqrt(double __X){
	__asm__(
		"fsqrt"
		: "=t" (__X)
		: "0" (__X)
	);
	return __X;
}

int main(int argc, char const *argv[]){
	if(argc == 2){
		double in = atof(argv[1]);
		printf("in : %4.8f\n", in);
		printf("cos: %4.8f\n", _cos(in));
		printf("sin: %4.8f\n", _sin(in));
		printf("sqrt: %4.8f\n", _sqrt(in));
		printf("sincos_c: %4.8f\n", _sincos_c(in));
		printf("sincos_s: %4.8f\n", _sincos_s(in));
		printf("in : %4.8f\n", in);
	}else{
		puts("give me one float input!");
		if(argc != 1){return 1;}
	}
	return 0;
}
