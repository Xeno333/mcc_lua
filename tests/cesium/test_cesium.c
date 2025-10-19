// ********* Cesium Header *********

typedef enum {false = 0, true = 1} bool;
signed long long cesium_main();


signed int argc = 0;
signed char** args = 0;

int main(signed int argc_passed, signed char** args_passed) {
    args = args_passed;
    argc = argc_passed;
    cesium_main();
}


// ********* End Cesium Header *********



//********* Start C include *********

#include "stdio.h"
#include "stdlib.h"
#include "string.h"
const unsigned long long cesium_ptr_to_u64 ( const void * v ) {;
return ( const unsigned long long ) v;
};

// ********* End C include *********

unsigned long long cesium_getstrlen (const unsigned char* cesium_2_getstrlen_str) {
	unsigned long long cesium_2_getstrlen_r = 0;

	while (cesium_2_getstrlen_str[cesium_2_getstrlen_r]!= 0) {;
		cesium_2_getstrlen_r ++;
	};
	cesium_2_getstrlen_r ++;
	return cesium_2_getstrlen_r;
};

void cesium_printbool (const bool cesium_4_v) {

	if (cesium_4_v == true) {;
		printf ("true");
	};

	if (cesium_4_v != true) {;
		printf ("false");
	};
};

void cesium_print (const unsigned char* cesium_7_s) {
	printf ("%s\n", cesium_7_s);
};

//********* Start C include *********

const unsigned long long * cesium_fopen ( const unsigned char * fn , const unsigned char * m ) {;
return ( const unsigned long long * ) fopen ( ( char * ) fn , ( char * ) m );
};
const signed long long cesium_fwrite ( const unsigned char * block , const unsigned long long size , const unsigned long long len , const unsigned long long * f ) {;
return fwrite ( ( void * ) block , size , len , ( FILE * ) f );
};
const signed long long cesium_fread ( const unsigned char * block , const unsigned long long size , const unsigned long long len , const unsigned long long * f ) {;
return fread ( ( void * ) block , size , len , ( FILE * ) f );
};
const signed long long cesium_fclose ( const unsigned long long * f ) {;
return fclose ( ( FILE * ) f );
};
const void cesium_fseek ( const unsigned long long * f , const unsigned long long start , const unsigned long long end ) {;
fseek ( ( FILE * ) f , start , end );
};
const signed long long cesium_ftell ( const unsigned long long * f ) {;
return ftell ( ( FILE * ) f );
};

// ********* End C include *********

signed int cesium_append (const unsigned char* cesium_15_fn, const unsigned char* cesium_15_block, const unsigned long long cesium_15_size) {
	const unsigned long long* cesium_15_f = cesium_fopen (cesium_15_fn, "a");
	cesium_fwrite (cesium_15_block, 1, cesium_15_size, cesium_15_f);
	cesium_fclose (cesium_15_f);
	return 0;
};

unsigned long long cesium_fsize (const unsigned char* cesium_16_fn) {
	const unsigned long long* cesium_16_f = cesium_fopen (cesium_16_fn, "rb");
	cesium_fseek (cesium_16_f, 0, SEEK_END);
	const unsigned long long cesium_16_size = cesium_ftell (cesium_16_f);
	cesium_fclose (cesium_16_f);
	return cesium_16_size;
};

unsigned long long cesium_fget (const unsigned char* cesium_17_fn) {
	const unsigned long long* cesium_17_f = cesium_fopen (cesium_17_fn, "rb");

	if (cesium_17_f == 0) {;
		return 0;
	};
	const unsigned long long cesium_17_size = cesium_fsize (cesium_17_fn);
	unsigned char* cesium_17_block = malloc (cesium_17_size + 1);
	cesium_fread (cesium_17_block, 1, cesium_17_size, cesium_17_f);
	cesium_fclose (cesium_17_f);
	cesium_17_block[cesium_17_size + 1]= 0;
	return cesium_ptr_to_u64 (cesium_17_block);
};
const unsigned char* cesium_str = "Hello, World";

signed long long cesium_main () {
	printf ("%s # %llu\n", cesium_str, cesium_getstrlen (cesium_str));
	cesium_print ("Hello from stdlib.cesium");
	return 0;
};
