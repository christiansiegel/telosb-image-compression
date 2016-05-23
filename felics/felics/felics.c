#include "felics.h"

//#define STATIC_K

enum {
	MAX_VAL = 255,
	K = 2,
	MAX_K = 8, // = ceillog_2(MAX_VAL)
	IN_RANGE     = 0,
	OUT_OF_RANGE = 1,
	BELOW_RANGE  = 0,
	ABOVE_RANGE  = 1
};

uint32_t encode(uint8_t *img_in, uint8_t *img_out)
{
	set_encoded_buf_for_encoding(img_out);

	// neighbor memory      // ****456789...255
	uint8_t line[256];      // 0123P*****...255

#ifndef STATIC_K
	uint32_t cumul_k[MAX_K];
	memset(cumul_k, 0, sizeof(cumul_k));
#endif // !STATIC_K

	uint8_t x = 0;
	uint8_t y = 0;
	uint32_t xy = 0;
	do {
		do {
			//
			// Step 1: 
			//
			uint8_t P, N1, N2;

			P = img_in[xy++];

			if (y > 0)
			{
				if (x > 0)
				{
					N1 = line[x - 1];
					N2 = line[x];
				}
				else
				{
					N1 = line[x];
					N2 = line[x + 1];
				}
			}
			else
			{
				if (x > 1)
				{
					N1 = line[x - 1];
					N2 = line[x - 2];
				}
				else if (x > 0)
				{
					N1 = line[x - 1];
					N2 = N1;
				}
				else
				{
					line[x] = P;            
					write_byte(P);         
					continue;              
				}
			}

			line[x] = P;

			//
			// Step 2:
			//
			uint8_t L, H, delta;

			if (N1 > N2) {
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

			if ((L <= P) && (P <= H))
			{
				//
				// (a):   
				//       
				write_bit(IN_RANGE);

				if (delta > 0)
					adjusted_binary_encode(P - L, delta + 1);
			}
			else
			{
				//
				// (b):
				// (c): 
				//       
				write_bit(OUT_OF_RANGE);

				uint8_t diff;
				if (P < L)
				{
					write_bit(BELOW_RANGE);
					diff = L - P - 1;
				}
				else
				{
					write_bit(ABOVE_RANGE);
					diff = P - H - 1;
				}

#ifndef STATIC_K
				uint8_t k = 0;

				uint32_t min = cumul_k[0];
				for (uint8_t i = 1; i < MAX_K; i++)
				{
					if (cumul_k[i] < min)
					{
						min = cumul_k[i];
						k = i;
					}
				}

				golomb_rice_encode(diff, k);

				for (uint8_t i = 0; i < MAX_K; i++)
					cumul_k[i] += (diff >> i) + 1 + i;
#else
				golomb_rice_encode(diff, K);
#endif

				
			}
		} while (x++ != 255);
	} while (y++ != 255);

	write_bit_flush();

	return get_encoded_length();
}

void decode(uint8_t *img_in, uint8_t *img_out)
{
	set_encoded_buf_for_decoding(img_in);

	// neighbor memory      // ****456789...255
	uint8_t line[256];      // 0123P*****...255

#ifndef STATIC_K
	uint32_t cumul_k[MAX_K];
	memset(cumul_k, 0, sizeof(cumul_k));
#endif

	uint8_t x = 0;
	uint8_t y = 0;
	uint32_t xy = 0;

	do {
		do {
			//
			// Step 1: 
			//       
			uint8_t P, N1, N2;

			if (y > 0)
			{
				if (x > 0)
				{                             
					N1 = line[x - 1];       
					N2 = line[x];
				}                             
				else
				{                            
					N1 = line[x];            
					N2 = line[x + 1];          
				}                              
			}
			else
			{
				if (x > 1)
				{
					N1 = line[x - 1];        
					N2 = line[x - 2];         
				}                            
				else if (x > 0)
				{
					N1 = line[x - 1];         
					N2 = N1;                    
				}                             
				else
				{
					line[x] = P = read_byte(); 
					img_out[xy++] = P;         
					continue;     
				}
			}

			//
			// Step 2:
			//         
			uint8_t L, H, delta;

			if (N1 > N2) {
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
			if (read_bit() == IN_RANGE)
			{
				P = delta > 0 ? adjusted_binary_decode(delta + 1) + L : L;
			}
			else
			{
				uint8_t flag = read_bit();

#ifndef STATIC_K
				uint8_t k = 0;
				uint32_t min = cumul_k[0];
				for (uint8_t i = 1; i < MAX_K; i++)
				{
					if (cumul_k[i] < min)
					{
						min = cumul_k[i];
						k = i;
					}
				}

				uint8_t diff = golomb_rice_decode(k);

				for (uint8_t i = 0; i < MAX_K; i++)
					cumul_k[i] += (diff >> i) + 1 + i;
#else
				uint8_t diff = golomb_rice_decode(K);
#endif

				if (flag == BELOW_RANGE)
					P = L - diff - 1;
				else
					P = diff + H + 1;
			}

			line[x] = P;
			img_out[xy++] = P;

		} while (x++ != 255);
	} while (y++ != 255);
}
