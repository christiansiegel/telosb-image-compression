#ifndef FELICS_H
#define FELICS_H

#include <assert.h>
#include <stdint.h>


uint8_t *m_encoded_buf;      // encoded buffer
uint32_t m_encoded_buf_pos;  // byte pos

uint8_t m_encoded_bit_buf;      // single bit buffer
uint8_t m_encoded_bit_buf_pos;  // bit pos

/**
* Resets @see m_encoded_bit_buf to zero and resets
* @see m_encoded_bit_buf_pos for encoding.
*/
static inline void reset_encoded_bit_buf_for_encoding()
{
	m_encoded_bit_buf = 0;
	m_encoded_bit_buf_pos = 8;
}

/**
* Resets @see m_encoded_bit_buf to zero and resets
* @see m_encoded_bit_buf_pos for decoding.
*/
static inline void reset_encoded_bit_buf_for_decoding()
{
	m_encoded_bit_buf = 0;
	m_encoded_bit_buf_pos = 0; // pos will be set to 8 on first bit read
}

/**
* Sets @param data as encoded buffer.
* Make sure it is big enough!!
*/
static inline void set_encoded_buf_for_encoding(uint8_t *data)
{
	m_encoded_buf = data;
	m_encoded_buf_pos = 0;
	reset_encoded_bit_buf_for_encoding();
}

/**
* Sets @param data as encoded buffer.
* Make sure it is big enough!!
*/
static inline void set_encoded_buf_for_decoding(uint8_t *data)
{
	m_encoded_buf = data;
	m_encoded_buf_pos = 0;
	reset_encoded_bit_buf_for_decoding();
}

/**
* Returns number of encoded bytes.
*/
static inline uint32_t get_encoded_length()
{
	return m_encoded_buf_pos;
}

/**
* Writes @param byte to @see m_encoded_buf and
* increases @see m_encoded_buf_pos to next byte
* position.
*/
static inline void write_byte(uint8_t byte)
{
	m_encoded_buf[m_encoded_buf_pos++] = byte;
}

/**
* Writes @param bit to @see m_encoded_bit_buf and
* eventually writes full byte to @see m_encoded_buf.
*
* @see write_bit_flush() to force writing bit buffer
*      to @see m_encoded_buf
*/
static inline void write_bit(uint8_t bit)
{
	--m_encoded_bit_buf_pos;

	if (bit)
		m_encoded_bit_buf |= (1 << m_encoded_bit_buf_pos);

	if (m_encoded_bit_buf_pos == 0)
	{
		write_byte(m_encoded_bit_buf);
		reset_encoded_bit_buf_for_encoding();
	}
}

/**
* Force write @see m_encoded_bit_buf to
* @see _encoded_buf.
*/
static inline void write_bit_flush()
{
	if (m_encoded_bit_buf_pos != 8)
	{
		write_byte(m_encoded_bit_buf);
		reset_encoded_bit_buf_for_encoding();
	}
}

/**
* Reads byte from @see m_encoded_buf and
* increases @see m_encoded_buf_pos to next byte
* position.
* Attention: If @see read_bit() is used be aware
*            that it reads a whole byte and stores
*            it in @see m_encoded_bit_buf.
*/
static inline uint8_t read_byte()
{
	return m_encoded_buf[m_encoded_buf_pos++];
}

/**
* Reads bit from @see m_encoded_bit_buf and
* fetches a new byte from @see m_encoded_buf if
* bit buffer was read completely.
*/
static inline uint8_t read_bit()
{
	if (m_encoded_bit_buf_pos == 0)
	{
		m_encoded_bit_buf = read_byte();
		m_encoded_bit_buf_pos = 8;
	}

	return (m_encoded_bit_buf >> --m_encoded_bit_buf_pos) & 1;
}

/**
* Calculates ceil(log2(x)).
*/
static inline uint8_t ceillog2(uint16_t x)
{
	assert(x > 0);

	uint8_t res = 0;
	--x;
	while (x)
	{
		x >>= 1;
		++res;
	}
	return res;
}

static inline uint8_t binary_decode(uint16_t range) // range = 2..256
{
	assert(range >= 2);
	assert(range <= 256);

	uint8_t bits = ceillog2(range);
	uint8_t thresh = (1 << bits) - range;

	uint16_t x = 0;
	for (uint8_t i = 0; i < bits - 1; i++)
		x += x + read_bit();

	if (x >= thresh)
	{
		x += x + read_bit();
		x -= thresh;
	}

	return (uint8_t)x;
}

// See 2.2 Adjusted binary codes
// range = 2..256
// x = 0..255; x < range
static inline void adjusted_binary_encode(uint16_t x, uint16_t range) 
{
	assert(range >= 2);
	assert(range <= 256);
	assert(x < range);

	int8_t bits = ceillog2(range); 
	uint8_t thresh = (1 << bits) - range; 

	// ADJUSTED PART START ------------

	x -= ((range - thresh) >> 1);
	if ((int16_t)x < 0)
		x += range;

	// ADJUSTED PART END --------------    

	if (x < thresh)
		--bits;
	else
		x += thresh;

	while ((--bits) >= 0)
		write_bit((x >> bits) & 0x1);
}

static inline void binary_encode(uint16_t x, uint16_t range)
{
	assert(range >= 2);
	assert(range <= 256);
	assert(x < range);

	int8_t bits = ceillog2(range);
	uint8_t thresh = (1 << bits) - range;

	if (x < thresh)
		--bits;
	else
		x += thresh;

	while ((--bits) >= 0)
		write_bit((x >> bits) & 0x1);
}

static inline uint8_t adjusted_binary_decode(uint16_t range) // range = 2..256
{
	assert(range >= 2);
	assert(range <= 256);

	uint8_t bits = ceillog2(range);
	uint8_t thresh = (1 << bits) - range; 

	uint16_t x = 0;
	for (uint8_t i = 0; i < bits - 1; i++)
		x += x + read_bit();

	if (x >= thresh)
	{
		x += x + read_bit();
		x -= thresh;
	}

	// ADJUSTED PART START ------------

	x += ((range - thresh) >> 1);
	if ((int16_t)x >= range)
		x -= range;

	// ADJUSTED PART END --------------

	return (uint8_t)x;
}


/**
* 0 -> 0
* 1 -> 10
* 2 -> 110
* 3 -> 1110
* ...
*/
static inline void unary_encode(uint16_t x)
{
	while (x--)
		write_bit(1);
	write_bit(0);
}

static inline uint16_t unary_decode()
{
	uint16_t x = 0;
	while (read_bit())
		++x;
	return x;
}


static inline void golomb_rice_encode(uint8_t x, uint8_t k)
{
	unary_encode(x >> k);
	if (k > 0)
		binary_encode(x & ((1 << k) - 1), 1 << k);
}

static inline uint8_t golomb_rice_decode(uint8_t k)
{
	uint8_t x;
	x = unary_decode() << k;
	if (k > 0)
		x |= binary_decode(1 << k);
	return x;
}

uint32_t encode(uint8_t *img_in, uint8_t *img_out);
void decode(uint8_t *img_in, uint8_t *img_out);

#endif