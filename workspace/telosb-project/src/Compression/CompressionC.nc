#include "config.h"

#if COMPRESS_IN_BUF_SIZE % COMPRESS_BLOCK_SIZE != 0
#error "COMPRESS_IN_BUF_SIZE has to be a multiple of COMPRESS_BLOCK_SIZE!"
#endif

module CompressionC {
	provides interface ProcessInput as Compression;
	uses interface CircularBuffer as OutBuffer;
}
implementation {
	uint8_t _running;
	uint32_t _byte_cnt;

	uint16_t _in_buf_byte_cnt;
	uint8_t * _in_buf;

	#ifdef FELICS
	#if COMPRESS_BLOCK_SIZE % 256 != 0
	#error "COMPRESS_BLOCK_SIZE has to be a multiple of 256 when using FELICS!"
	#endif
	enum {
		K = 4,
		IN_RANGE = 0,
		OUT_OF_RANGE = 1,
		BELOW_RANGE = 0,
		ABOVE_RANGE = 1
	};

	uint8_t x, y;

	uint8_t m_encoded_bit_buf; // single bit buffer
	uint8_t m_encoded_bit_buf_pos; // bit pos    

	// neighbor memory      // ****456789...255
	uint8_t line[256]; // 0123P*****...255     

	inline void write_byte(uint8_t byte) {
		call OutBuffer.write(byte); 
		// TODO: Error if byte can't be written. This only happens on worst case images though
		// TODO: Use local buffer to write to cyclic buffer in blocks -> increases speed?
	}

	inline void write_bit(uint8_t bit) {
		--m_encoded_bit_buf_pos;

		if(bit) 
			m_encoded_bit_buf |= (1 << m_encoded_bit_buf_pos);

		if(m_encoded_bit_buf_pos == 0) {
			write_byte(m_encoded_bit_buf);
			m_encoded_bit_buf = 0;
			m_encoded_bit_buf_pos = 8;
		}
	}

	inline uint8_t ceillog2(uint16_t a) {
		uint8_t res = 0;
		--a;
		while(a) {
			a >>= 1;
			++res;
		}
		return res;
	}

	inline void adjusted_binary_encode(uint16_t a, uint16_t range) {
		int8_t bits = ceillog2(range);
		uint8_t thresh = (uint8_t)((1 << bits) - range);

		// ADJUSTED PART START ------------    

		a -= ((range - thresh) >> 1);
		if((int16_t) a < 0) 
			a += range;

		// ADJUSTED PART END --------------        

		if(a < thresh)
			--bits;
		else 
			a += thresh;

		while((--bits) >= 0) 
			write_bit((uint8_t)(a >> bits)& 0x1);
	}

	inline void binary_encode(uint16_t a, uint16_t range) {
		int8_t bits = ceillog2(range);
		uint8_t thresh = (uint8_t)((1 << bits) - range);

		if(a < thresh)
			--bits;
		else 
			a += thresh;

		while((--bits) >= 0) 
			write_bit((uint8_t)(a >> bits)& 0x1);
	}

	inline void unary_encode(uint16_t a) {
		while(a--) 
			write_bit(1);
		write_bit(0);
	}

	inline void golomb_rice_encode(uint8_t a, uint8_t k) {
		unary_encode(a >> k);
		if(k > 0) 
			binary_encode(a & ((1 << k) - 1), 1 << k);
	}

	inline void write_bit_flush() {
		if(m_encoded_bit_buf_pos != 8) {
			write_byte(m_encoded_bit_buf);
			m_encoded_bit_buf = 0;
			m_encoded_bit_buf_pos = 8;
		}
	}

	inline void compress_block() {
		uint8_t P, N1, N2, L, H, delta, diff, i;

		if(call OutBuffer.free() < COMPRESS_BLOCK_SIZE){ // TODO: Worst case image can still exceed this!
			return;
		}

		for(i = 0; i < COMPRESS_BLOCK_SIZE / 256; ++i) {
			do {
				//
				// Step 1: 
				//   

				P = _in_buf[_in_buf_byte_cnt + x];

				if(y > 0) {
					if(x > 0) {
						N1 = line[x - 1];
						N2 = line[x];
					}
					else {
						N1 = line[x];
						N2 = line[x + 1];
					}
				}
				else {
					if(x > 1) {
						N1 = line[x - 1];
						N2 = line[x - 2];
					}
					else 
						if(x > 0) {
						N1 = line[x - 1];
						N2 = N1;
					}
					else {
						line[x] = P;
						write_byte(P);
						continue;
					}
				}

				line[x] = P;

				//
				// Step 2:
				//   

				if(N1 > N2) {
					H = N1;
					L = N2;
				}
				else {
					H = N2;
					L = N1;
				}

				delta = H - L;

				//
				// Step 3:
				//     

				if((L <= P)&&(P <= H)) {
					//
					// (a):   
					//       
					write_bit(IN_RANGE);

					if(delta > 0) 
						adjusted_binary_encode(P - L, delta + 1);
				}
				else {
					//
					// (b):
					// (c): 
					//       
					write_bit(OUT_OF_RANGE);

					if(P < L) {
						write_bit(BELOW_RANGE);
						diff = L - P - 1;
					}
					else {
						write_bit(ABOVE_RANGE);
						diff = P - H - 1;
					}

					golomb_rice_encode(diff, K);
				}
			}
			while(x++ != 255);
			y++;
		}
		_byte_cnt += COMPRESS_BLOCK_SIZE;
		if(_byte_cnt == 65536) {
		  write_bit_flush();	
		}
		
		_in_buf_byte_cnt += COMPRESS_BLOCK_SIZE;
	}
	#elif defined(TRUNCATE_1)
	#if COMPRESS_BLOCK_SIZE % 8 != 0
	#error "COMPRESS_BLOCK_SIZE has to be a multiple of 8 when using TRUNCATE_1!"
	#endif
	inline void compress_block() {
		uint8_t tmp[COMPRESS_BLOCK_SIZE / 8 * 7], j, sliced = 0;
		uint16_t i;
		if(call OutBuffer.free() >= sizeof(tmp)) {
			for(i = 0, j = 0; i < sizeof(tmp); i++) {
				if(j++ == 0) {
					sliced = _in_buf[_in_buf_byte_cnt + 7];
				}
				tmp[i] = _in_buf[_in_buf_byte_cnt++]& 0xFE;
				tmp[i] |= (sliced >>= 1)& 0x01;
				if(j == 7) {
					j = 0;
					_in_buf_byte_cnt++;
				}
			}
			call OutBuffer.write_block(tmp, sizeof(tmp));
			_byte_cnt += COMPRESS_BLOCK_SIZE;
		}
	}
	#elif defined(TRUNCATE_2)
	#if COMPRESS_BLOCK_SIZE % 4 != 0
	#error "COMPRESS_BLOCK_SIZE has to be a multiple of 4 when using TRUNCATE_2!"
	#endif
	inline void compress_block() {
		uint8_t tmp[COMPRESS_BLOCK_SIZE / 4 * 3], j, sliced = 0;
		uint16_t i;
		if(call OutBuffer.free() >= sizeof(tmp)) {
			for(i = 0, j = 0; i < sizeof(tmp); i++) {
				if(j++ == 0) {
					sliced = _in_buf[_in_buf_byte_cnt + 3];
				}
				tmp[i] = _in_buf[_in_buf_byte_cnt++]& 0xFC;
				tmp[i] |= (sliced >>= 2)& 0x03;
				if(j == 3) {
					j = 0;
					_in_buf_byte_cnt++;
				}
			}
			call OutBuffer.write_block(tmp, sizeof(tmp));
			_byte_cnt += COMPRESS_BLOCK_SIZE;
		}
	}
	#elif defined(TRUNCATE_4)
	#if COMPRESS_BLOCK_SIZE % 2 != 0
	#error "COMPRESS_BLOCK_SIZE has to be a multiple of 2 when using TRUNCATE_4!"
	#endif
	inline void compress_block() {
		uint8_t tmp[COMPRESS_BLOCK_SIZE / 2];
		uint16_t i;
		if(call OutBuffer.free() >= sizeof(tmp)) {
			for(i = 0; i < sizeof(tmp); i++) {
				tmp[i] = _in_buf[_in_buf_byte_cnt++]& 0xF0;
				tmp[i] |= _in_buf[_in_buf_byte_cnt++] >> 4;
			}
			call OutBuffer.write_block(tmp, sizeof(tmp));
			_byte_cnt += COMPRESS_BLOCK_SIZE;
		}
	}
	#endif 

	task void compress() {
		if(_byte_cnt == 65536) {
			_running = FALSE;
			signal Compression.done();
			return;
		}
		else 
			if(_in_buf == NULL) {
			// do nothing until new input buffer is provided;
		}
		else 
			if(_in_buf_byte_cnt == COMPRESS_IN_BUF_SIZE) {
			uint8_t * tmp = _in_buf;

			_in_buf_byte_cnt = 0;
			_in_buf = NULL;
			signal Compression.consumed_input(tmp);
		}
		else {
			compress_block();
		}
		post compress();
	}

	command error_t Compression.start() {
		if(_running) {
			return EBUSY;
		}
		else {
			_running = TRUE;
			_byte_cnt = 0;
			_in_buf = NULL;
			_in_buf_byte_cnt = 0;
			#ifdef FELICS
			x = 0;
			y = 0;
			m_encoded_bit_buf = 0;
			m_encoded_bit_buf_pos = 8;
			#endif
			call OutBuffer.clear();
			post compress();
			return SUCCESS;
		}
	}

	command error_t Compression.new_input(uint8_t * buf) {
		if(_running == FALSE) {
			return ECANCEL;
		}
		else 
			if(_in_buf != NULL) {
			return EBUSY;
		}
		else {
			_in_buf = buf;
			_in_buf_byte_cnt = 0;
			post compress();
			return SUCCESS;
		}
	}
}