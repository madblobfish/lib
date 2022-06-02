// gcc test.c -fopenmp -lcrypto
// gcc -std=c17 -Wall -Wextra -pedantic-errors -Werror -flto -O2 -march=native md5bruteforce.c -fopenmp -lcrypto && time ./a.out sha1 7E240DE74FB1ED08FA08D38063F6A6A91462A815

#include <string.h>
#include <openssl/md5.h>
#include <openssl/evp.h>
#include <limits.h>
#include <omp.h>

#define HASH_SIZE(hash) \
	EVP_MD_size(EVP_get_digestbyname(hash))
#define HASH(str,len,hash,out) \
	EVP_MD_CTX* c = EVP_MD_CTX_new(); \
	EVP_DigestInit_ex(c, EVP_get_digestbyname(hash), NULL); \
	EVP_DigestUpdate(c, str, len);\
	EVP_DigestFinal_ex(c, out, NULL);\
	EVP_MD_CTX_free(c);
#define MD5(str,len,out) \
	MD5_CTX c;\
	MD5_Init(&c);\
	MD5_Update(&c, str, len);\
	MD5_Final(out, &c);


char* int_to_str(unsigned long long in){
	char* out = calloc(41, sizeof(char));
	unsigned long long copy = in;
	for(int i = 0; i < 40; ++i){
		out[i] = copy & 255;
		copy = copy >> 8;
		if(copy == 0) break;
	}
	return out;
}

char hexchar_to_int(const char c){
	if(c >= '0' && c <= '9') return c - '0';
	if(c >= 'A' && c <= 'F') return c - 'A' + 10;
	if(c >= 'a' && c <= 'f') return c - 'a' + 10;
	puts("could not convert input from hex");
	exit(1);
}
const char* hex_to_bytes(const char* str){
	unsigned int len = strlen(str)/2;
	char* out = calloc(len, sizeof(char));
	for(int i = 0; i < len; ++i){
		out[i] = hexchar_to_int(str[i*2])*16 + hexchar_to_int(str[i*2+1]);
	}
	return out;
}

void printthing(unsigned char* hash, unsigned int len){
	for(int i = 0; i < len; ++i){
		printf("%02X", hash[i]);
	}
	puts("");
}

void crack(const char* target_hex, const char* hash_type, const unsigned int size){
	const char* target = hex_to_bytes((const char*)target_hex);
	const EVP_MD * bla = EVP_get_digestbyname(hash_type);
	#pragma omp parallel default(none) shared(size,bla,target)
	{
		EVP_MD_CTX* c = EVP_MD_CTX_new();

		#pragma omp for
		for(unsigned long long i = 0; i < ULLONG_MAX; ++i){
			unsigned char hash[size];
			char* str = int_to_str(i);
			// MD5(str, strlen(str), hash);
			// HASH(str, strlen(str), "md5", hash);
			EVP_DigestInit_ex(c, bla, NULL);
			EVP_DigestUpdate(c, str, strlen(str));
			EVP_DigestFinal_ex(c, hash, NULL);
			if(memcmp(hash, target, size)==0){
				#pragma omp critical
				{
				puts("Got it!");
				printf("Decimal: %llu\nHex:	 %llx\nString:  ", i, i);
				puts(str);
				exit(0);
				}
			}
			free(str);
		}
	}
}

int main(const int argc, char *argv[]){
	char* hash_to_use = "md5";
	char* inp = argv[1];
	if(argc == 3){
		if(EVP_get_digestbyname(argv[1]) == NULL){
			puts("Hashfunction not found");
			exit(1);
		}
		hash_to_use = argv[1];
		inp = argv[2];
	}
	if(argc == 2 || argc == 3){
		const unsigned int size = HASH_SIZE(hash_to_use);
		if(strlen(inp) == size*2){
			crack(inp, hash_to_use, size);
			puts("No result found in search space");
			return 2;
		}else{
			unsigned char hash[size];
			HASH(inp, strlen(inp), hash_to_use, hash);
			printthing(hash, size);
		}
	}else{
		printf("%s [hashname] tohash|hash\n\n", argv[0]);
		puts("input a string to hash");
		puts("or input something else to hash it (it depends on length)");
		puts("hashname is md5 by default");
	}
	return 0;
}
