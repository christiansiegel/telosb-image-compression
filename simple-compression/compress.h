#ifndef COMPRESS_H
#define COMPRESS_H

//#include <assert.h>
#include <stdint.h>

void encode1(uint8_t *img_in, uint8_t *img_out);
void encode2(uint8_t *img_in, uint8_t *img_out);
void encode4(uint8_t *img_in, uint8_t *img_out);

void decode1(uint8_t *img_in, uint8_t *img_out);
void decode2(uint8_t *img_in, uint8_t *img_out);
void decode4(uint8_t *img_in, uint8_t *img_out);

#endif
