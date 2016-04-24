// felics.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include "minunit.h"
#include "felics.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define TEST_IMG_PATH "C:/Projects/felics/felics/test-images/"

uint8_t buffer[9999999];

void setup_fun(void)
{
	memset(buffer, 0, sizeof(buffer));
}

MU_TEST(test_int_size)
{
	mu_assert_int_eq(sizeof(int32_t), sizeof(int));
}

MU_TEST(test_ceillog_2)
{
	for (int i = 1; i <= 65535; ++i)
	{
		int expected = (int)(ceil(log(i) / log(2)));
		uint8_t result = ceillog2(i);
		mu_assert_int_eq(expected, result);
	}
}

MU_TEST(test_write)
{
	set_encoded_buf_for_encoding(buffer);

	write_byte(0b10101010);

	write_bit(0);
	write_bit(0);
	write_bit(0);
	write_bit(0);
	write_bit(1);
	write_bit(0);
	write_bit(0);
	write_bit(1);

	write_bit(0);
	write_bit(1);

	mu_assert_int_eq(2, get_encoded_length());

	write_bit_flush();

	mu_assert_int_eq(3, get_encoded_length());

	mu_assert_int_eq(0b10101010, buffer[0]);
	mu_assert_int_eq(0b00001001, buffer[1]);
	mu_assert_int_eq(0b01000000, buffer[2]);
	mu_assert_int_eq(0b00000000, buffer[3]);
}

MU_TEST(test_read)
{
	buffer[0] = 0b10101010;
	buffer[1] = 0b00001001;
	buffer[2] = 0b01000000;

	set_encoded_buf_for_decoding(buffer);

	mu_assert_int_eq(buffer[0], read_byte());

	read_bit();
	read_bit();
	read_bit();
	read_bit();

	mu_assert_int_eq(1, read_bit());
	mu_assert_int_eq(0, read_bit());
	mu_assert_int_eq(0, read_bit());
	mu_assert_int_eq(1, read_bit());
	mu_assert_int_eq(0, read_bit());
	mu_assert_int_eq(1, read_bit());
}

MU_TEST(test_unary_encode)
{
	set_encoded_buf_for_encoding(buffer);

	unary_encode(0);
	unary_encode(3);
	unary_encode(9);

	write_bit_flush();

	mu_assert_int_eq(0b01110111, buffer[0]);
	mu_assert_int_eq(0b11111100, buffer[1]);
}

MU_TEST(test_unary_decode)
{
	buffer[0] = 0b01110111;
	buffer[1] = 0b11111100;

	set_encoded_buf_for_decoding(buffer);

	mu_assert_int_eq(0, unary_decode());
	mu_assert_int_eq(3, unary_decode());
	mu_assert_int_eq(9, unary_decode());
}

MU_TEST(test_unary_encode_decode)
{
	set_encoded_buf_for_encoding(buffer);

	for (int i = 0; i <= 500; ++i)
		unary_encode(i);
	unary_encode(65535);
	write_bit_flush();

	set_encoded_buf_for_decoding(buffer);

	for (int i = 0; i <= 500; ++i)
		mu_assert_int_eq(i, unary_decode());
	mu_assert_int_eq(65535, unary_decode());
}

MU_TEST(test_binary_encode)
{
	set_encoded_buf_for_encoding(buffer);

	binary_encode(0, 2); write_bit_flush();
	binary_encode(1, 2); write_bit_flush();

	binary_encode(0, 4); write_bit_flush();
	binary_encode(1, 4); write_bit_flush();
	binary_encode(3, 4); write_bit_flush();

	binary_encode(0, 8); write_bit_flush();
	binary_encode(3, 8); write_bit_flush();
	binary_encode(7, 8); write_bit_flush();

	binary_encode(0, 16); write_bit_flush();
	binary_encode(7, 16); write_bit_flush();
	binary_encode(15, 16); write_bit_flush();

	binary_encode(0, 32); write_bit_flush();
	binary_encode(15, 32); write_bit_flush();
	binary_encode(31, 32); write_bit_flush();

	binary_encode(0, 64); write_bit_flush();
	binary_encode(31, 64); write_bit_flush();
	binary_encode(63, 64); write_bit_flush();

	binary_encode(0, 128); write_bit_flush();
	binary_encode(63, 128); write_bit_flush();
	binary_encode(127, 128); write_bit_flush();

	binary_encode(0, 256); write_bit_flush();
	binary_encode(127, 256); write_bit_flush();
	binary_encode(255, 256); write_bit_flush();

	mu_assert_int_eq(0b00000000, buffer[0]);
	mu_assert_int_eq(0b10000000, buffer[1]);

	mu_assert_int_eq(0b00000000, buffer[2]);
	mu_assert_int_eq(0b01000000, buffer[3]);
	mu_assert_int_eq(0b11000000, buffer[4]);

	mu_assert_int_eq(0b00000000, buffer[5]);
	mu_assert_int_eq(0b01100000, buffer[6]);
	mu_assert_int_eq(0b11100000, buffer[7]);

	mu_assert_int_eq(0b00000000, buffer[8]);
	mu_assert_int_eq(0b01110000, buffer[9]);
	mu_assert_int_eq(0b11110000, buffer[10]);

	mu_assert_int_eq(0b00000000, buffer[11]);
	mu_assert_int_eq(0b01111000, buffer[12]);
	mu_assert_int_eq(0b11111000, buffer[13]);

	mu_assert_int_eq(0b00000000, buffer[14]);
	mu_assert_int_eq(0b01111100, buffer[15]);
	mu_assert_int_eq(0b11111100, buffer[16]);

	mu_assert_int_eq(0b00000000, buffer[17]);
	mu_assert_int_eq(0b01111110, buffer[18]);
	mu_assert_int_eq(0b11111110, buffer[19]);

	mu_assert_int_eq(0b00000000, buffer[20]);
	mu_assert_int_eq(0b01111111, buffer[21]);
	mu_assert_int_eq(0b11111111, buffer[22]);
}

MU_TEST(test_binary_encode_decode)
{
	set_encoded_buf_for_encoding(buffer);

	for (int range = 2; range <= 256; ++range)
		for (int x = 0; x < range; ++x)
			binary_encode(x, range);

	write_bit_flush();

	set_encoded_buf_for_decoding(buffer);

	for (int range = 2; range <= 256; ++range)
		for (int x = 0; x < range; ++x)
			mu_assert_int_eq(x, binary_decode(range));
}

MU_TEST(test_adjusted_binary_encode)
{
	set_encoded_buf_for_encoding(buffer);

	adjusted_binary_encode(0, 2); write_bit_flush();
	adjusted_binary_encode(1, 2); write_bit_flush();

	adjusted_binary_encode(0, 4); write_bit_flush();
	adjusted_binary_encode(1, 4); write_bit_flush();
	adjusted_binary_encode(3, 4); write_bit_flush();

	adjusted_binary_encode(0, 8); write_bit_flush();
	adjusted_binary_encode(3, 8); write_bit_flush();
	adjusted_binary_encode(7, 8); write_bit_flush();

	adjusted_binary_encode(0, 16); write_bit_flush();
	adjusted_binary_encode(7, 16); write_bit_flush();
	adjusted_binary_encode(15, 16); write_bit_flush();

	adjusted_binary_encode(0, 32); write_bit_flush();
	adjusted_binary_encode(15, 32); write_bit_flush();
	adjusted_binary_encode(31, 32); write_bit_flush();

	adjusted_binary_encode(0, 64); write_bit_flush();
	adjusted_binary_encode(31, 64); write_bit_flush();
	adjusted_binary_encode(63, 64); write_bit_flush();

	adjusted_binary_encode(0, 128); write_bit_flush();
	adjusted_binary_encode(63, 128); write_bit_flush();
	adjusted_binary_encode(127, 128); write_bit_flush();

	adjusted_binary_encode(0, 256); write_bit_flush();
	adjusted_binary_encode(127, 256); write_bit_flush();
	adjusted_binary_encode(255, 256); write_bit_flush();

	mu_assert_int_eq(0b10000000, buffer[0]);
	mu_assert_int_eq(0b00000000, buffer[1]);

	mu_assert_int_eq(0b10000000, buffer[2]);
	mu_assert_int_eq(0b11000000, buffer[3]);
	mu_assert_int_eq(0b01000000, buffer[4]);

	mu_assert_int_eq(0b10000000, buffer[5]);
	mu_assert_int_eq(0b11100000, buffer[6]);
	mu_assert_int_eq(0b01100000, buffer[7]);

	mu_assert_int_eq(0b10000000, buffer[8]);
	mu_assert_int_eq(0b11110000, buffer[9]);
	mu_assert_int_eq(0b01110000, buffer[10]);

	mu_assert_int_eq(0b10000000, buffer[11]);
	mu_assert_int_eq(0b11111000, buffer[12]);
	mu_assert_int_eq(0b01111000, buffer[13]);

	mu_assert_int_eq(0b10000000, buffer[14]);
	mu_assert_int_eq(0b11111100, buffer[15]);
	mu_assert_int_eq(0b01111100, buffer[16]);

	mu_assert_int_eq(0b10000000, buffer[17]);
	mu_assert_int_eq(0b11111110, buffer[18]);
	mu_assert_int_eq(0b01111110, buffer[19]);

	mu_assert_int_eq(0b10000000, buffer[20]);
	mu_assert_int_eq(0b11111111, buffer[21]);
	mu_assert_int_eq(0b01111111, buffer[22]);
}

MU_TEST(test_adjusted_binary_encode_decode)
{
	set_encoded_buf_for_encoding(buffer);

	for (int range = 2; range <= 256; ++range)
		for (int x = 0; x < range; ++x)
			adjusted_binary_encode(x, range);

	write_bit_flush();

	set_encoded_buf_for_decoding(buffer);

	for (int range = 2; range <= 256; ++range)
		for (int x = 0; x < range; ++x)
			mu_assert_int_eq(x, adjusted_binary_decode(range));
}

MU_TEST(test_golomb_rice_encode)
{
	set_encoded_buf_for_encoding(buffer);

	golomb_rice_encode(0, 0); write_bit_flush();
	golomb_rice_encode(1, 0); write_bit_flush();
	golomb_rice_encode(7, 0); write_bit_flush();

	golomb_rice_encode(0, 1); write_bit_flush();
	golomb_rice_encode(1, 1); write_bit_flush();
	golomb_rice_encode(7, 1); write_bit_flush();

	golomb_rice_encode(0, 2); write_bit_flush();
	golomb_rice_encode(1, 2); write_bit_flush();
	golomb_rice_encode(7, 2); write_bit_flush();

	golomb_rice_encode(0, 3); write_bit_flush();
	golomb_rice_encode(1, 3); write_bit_flush();
	golomb_rice_encode(7, 3); write_bit_flush();
	golomb_rice_encode(255, 3); write_bit_flush();

	mu_assert_int_eq(0b00000000, buffer[0]);
	mu_assert_int_eq(0b10000000, buffer[1]);
	mu_assert_int_eq(0b11111110, buffer[2]);

	mu_assert_int_eq(0b00000000, buffer[3]);
	mu_assert_int_eq(0b01000000, buffer[4]);
	mu_assert_int_eq(0b11101000, buffer[5]);

	mu_assert_int_eq(0b00000000, buffer[6]);
	mu_assert_int_eq(0b00100000, buffer[7]);
	mu_assert_int_eq(0b10110000, buffer[8]);

	mu_assert_int_eq(0b00000000, buffer[9]);
	mu_assert_int_eq(0b00010000, buffer[10]);
	mu_assert_int_eq(0b01110000, buffer[11]);
	mu_assert_int_eq(0b11111111, buffer[12]);
}

MU_TEST(test_golomb_rice_encode_decode)
{
	set_encoded_buf_for_encoding(buffer);

	for (int k = 0; k <= 8; ++k)
		for (int x = 0; x <= 255; ++x)
			golomb_rice_encode(x, k);

	write_bit_flush();

	set_encoded_buf_for_decoding(buffer);

	for (int k = 0; k <= 8; ++k)
		for (int x = 0; x <= 255; ++x)
			mu_assert_int_eq(x, golomb_rice_decode(k));
}

MU_TEST(test_encode_decode_black)
{
	uint8_t img_orig[256 * 256];
	uint8_t img_enc[256 * 256];
	uint8_t img_dec[256 * 256];

	FILE *fp;
	fopen_s(&fp, TEST_IMG_PATH "black.bin", "rb");
	fread(img_orig, sizeof(img_orig), 1, fp);
	fclose(fp);

	int len = encode(img_orig, img_enc);
	decode(img_enc, img_dec);

	printf("black.bin compressed size = %d bytes\n", len);

	int diff = memcmp(img_orig, img_dec, sizeof(img_orig));
	mu_assert_int_eq(0, diff);
}

MU_TEST(test_encode_decode_white)
{
	uint8_t img_orig[256 * 256];
	uint8_t img_enc[256 * 256];
	uint8_t img_dec[256 * 256];

	FILE *fp;
	fopen_s(&fp, TEST_IMG_PATH "white.bin", "rb");
	fread(img_orig, sizeof(img_orig), 1, fp);
	fclose(fp);

	int len = encode(img_orig, img_enc);
	decode(img_enc, img_dec);

	printf("white.bin compressed size = %d bytes\n", len);

	int diff = memcmp(img_orig, img_dec, sizeof(img_orig));
	mu_assert_int_eq(0, diff);
}

MU_TEST(test_encode_decode_mix)
{
	uint8_t img_orig[256 * 256];
	uint8_t img_enc[256 * 256 * 2];
	uint8_t img_dec[256 * 256];

	FILE *fp;
	fopen_s(&fp, TEST_IMG_PATH "mix.bin", "rb");
	fread(img_orig, sizeof(img_orig), 1, fp);
	fclose(fp);

	int len = encode(img_orig, img_enc);
	decode(img_enc, img_dec);

	printf("mix.bin compressed size = %d bytes\n", len);

	int diff = memcmp(img_orig, img_dec, sizeof(img_orig));
	mu_assert_int_eq(0, diff);
}

MU_TEST_SUITE(test_suite)
{
	MU_SUITE_CONFIGURE(setup_fun, 0);

	MU_RUN_TEST(test_int_size);

	MU_RUN_TEST(test_ceillog_2);
	MU_RUN_TEST(test_write);
	MU_RUN_TEST(test_read);
	MU_RUN_TEST(test_unary_encode);
	MU_RUN_TEST(test_unary_decode);
	MU_RUN_TEST(test_unary_encode_decode);
	MU_RUN_TEST(test_binary_encode);
	MU_RUN_TEST(test_binary_encode_decode);
	MU_RUN_TEST(test_adjusted_binary_encode);
	MU_RUN_TEST(test_adjusted_binary_encode_decode);
	MU_RUN_TEST(test_golomb_rice_encode);
	MU_RUN_TEST(test_golomb_rice_encode_decode);

	MU_RUN_TEST(test_encode_decode_black);
	MU_RUN_TEST(test_encode_decode_white);
	MU_RUN_TEST(test_encode_decode_mix);
}

int main()
{
	MU_RUN_SUITE(test_suite);
	MU_REPORT();
	return 0;
}

