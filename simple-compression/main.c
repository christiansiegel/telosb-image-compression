
#include "minunit.h"
#include "compress.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>


uint8_t uncompressed[9999999];
uint8_t compressed[9999999];

void setup_fun(void)
{
	memset(uncompressed, 0, sizeof(uncompressed));
	memset(compressed, 0, sizeof(compressed));
}

MU_TEST(test_compress1)
{
    uncompressed[0] = 0b01000010;
    uncompressed[1] = 0b11111111;
    uncompressed[2] = 0b00000000;
    uncompressed[3] = 0b11111111; 
    uncompressed[4] = 0b00000000;
    uncompressed[5] = 0b11111111;
    uncompressed[6] = 0b00000000;
    uncompressed[7] = 0b11111111;            
    
    encode1(uncompressed, compressed);

	mu_assert_int_eq(0b01000011, compressed[0]);
	mu_assert_int_eq(0b11111100, compressed[1]);
	mu_assert_int_eq(0b00000111, compressed[2]);
	mu_assert_int_eq(0b11110000, compressed[3]);
	mu_assert_int_eq(0b00011111, compressed[4]);
	mu_assert_int_eq(0b11000000, compressed[5]);
	mu_assert_int_eq(0b01111111, compressed[6]);
}

MU_TEST(test_compress2)
{
    uncompressed[0] = 0b01000110;
    uncompressed[1] = 0b11111111;
    uncompressed[2] = 0b00000000;
    uncompressed[3] = 0b11111111;          
    
    encode2(uncompressed, compressed);

	mu_assert_int_eq(0b01000111, compressed[0]);
	mu_assert_int_eq(0b11110000, compressed[1]);
	mu_assert_int_eq(0b00111111, compressed[2]);
}

MU_TEST(test_compress4)
{
    uncompressed[0] = 0b01000110;
    uncompressed[1] = 0b11111011;        
    
    encode4(uncompressed, compressed);

	mu_assert_int_eq(0b01001111, compressed[0]);
}

MU_TEST(test_decompress4)
{
    compressed[0] = 0b01001011;       
    
    decode4(compressed, uncompressed);

	mu_assert_int_eq(0b01000000, uncompressed[0]);
	mu_assert_int_eq(0b10110000, uncompressed[1]);
}

MU_TEST(test_decompress2)
{
    compressed[0] = 0b01000111;    
    compressed[1] = 0b11110000;
    compressed[2] = 0b00111101;     
    
    decode2(compressed, uncompressed);

	mu_assert_int_eq(0b01000100, uncompressed[0]);
	mu_assert_int_eq(0b11111100, uncompressed[1]);
	mu_assert_int_eq(0b00000000, uncompressed[2]);
	mu_assert_int_eq(0b11110100, uncompressed[3]);
}

MU_TEST(test_decompress1)
{
    compressed[0] = 0b01000011;    
    compressed[1] = 0b11111101;
    compressed[2] = 0b10000101;  
    compressed[3] = 0b11110000;
    compressed[4] = 0b00011111;
    compressed[5] = 0b11000000;
    compressed[6] = 0b01110111;   

    decode1(compressed, uncompressed);

	mu_assert_int_eq(0b01000010, uncompressed[0]);
	mu_assert_int_eq(0b11111110, uncompressed[1]);
	mu_assert_int_eq(0b01100000, uncompressed[2]);
	mu_assert_int_eq(0b10111110, uncompressed[3]);
	mu_assert_int_eq(0b00000000, uncompressed[4]);
	mu_assert_int_eq(0b11111110, uncompressed[5]);
	mu_assert_int_eq(0b00000000, uncompressed[6]);
	mu_assert_int_eq(0b11101110, uncompressed[7]);
}

MU_TEST_SUITE(test_suite)
{
	MU_SUITE_CONFIGURE(setup_fun, 0);

	MU_RUN_TEST(test_compress1);
	MU_RUN_TEST(test_compress2);
	MU_RUN_TEST(test_compress4);
	
	MU_RUN_TEST(test_decompress4);
	MU_RUN_TEST(test_decompress2);
	MU_RUN_TEST(test_decompress1);
}

int main()
{
	MU_RUN_SUITE(test_suite);
	MU_REPORT();
	
	uint8_t img_orig[256 * 256];
	uint8_t img_enc[256 * 256 / 2];
	uint8_t img_dec[256 * 256];

	FILE *fp;
	fp = fopen( "chemicalplant.bin", "rb");
	fread(img_orig, sizeof(img_orig), 1, fp);
	fclose(fp);

    for(int i = 0; i < (256*256/2); ++i) {
        encode4(&img_orig[i*2], &img_enc[i]);
        decode4(&img_enc[i], &img_dec[i*2]);
    }
    
	fp = fopen( "chemicalplant_dec.bin", "wb");
	fwrite(img_dec , 1 , sizeof(img_dec) , fp );
	fclose(fp);
	
	return 0;
}

