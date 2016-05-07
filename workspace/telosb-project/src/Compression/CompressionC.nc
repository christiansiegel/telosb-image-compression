#include "Config.h"

#if COMPRESS_IN_BUF_SIZE % COMPRESS_BLOCK_SIZE != 0
#error "COMPRESS_IN_BUF_SIZE has to be a multiple of COMPRESS_BLOCK_SIZE!"
#endif

#if !(defined(FELICS) ^ defined(TRUNCATE_1) ^ defined(TRUNCATE_2) ^ \
      defined(TRUNCATE_4))
#error "You have to specify exactly one compression algorithm to use!"
#endif

/**
 * Compression of a 256x256 pixel greyscale image.
 *
 * Gradually takes input from a set of input buffers. Compressed data is output
 * continuously on the output circular buffer. Compression is done block-wise
 * whenever there is enough free space in the output buffer.
 */
module CompressionC {
  provides interface ProcessInput as Compression;
  uses interface CircularBuffer as OutBuffer;
}
implementation {
  /**
   * Compression is running.
   */
  bool _running;

  /**
   * Number of processed bytes.
   */
  uint32_t _bytes_processed;

  /**
   * Current input buffer.
   */
  uint8_t* _in_buf;

  /**
   * Current read position in input buffer.
   */
  uint16_t _in_buf_pos;

#ifdef FELICS
  enum {
    /**
     * Parameter K of Golomb-Rice codes.
     */
    K = 4,
    /**
     * Bit flag for pixel values that are in the range of their two neighbors.
     */
    IN_RANGE = 0,
    /**
     * Bit flag for pixel values that are out of the range of their two
     * neighbors.
     */
    OUT_OF_RANGE = 1,
    /**
     * Bit flag for pixel values that are below the range of their two
     * neighbors.
     */
    BELOW_RANGE = 0,
    /**
     * Bit flag for pixel values that are above the range of their two
     * neighbors.
     */
    ABOVE_RANGE = 1
  };

  /**
   * X-coordinate of currently processed pixel.
   */
  uint8_t x;

  /**
   * Y-coordinate of currently processed pixel.
   */
  uint8_t y;

  /**
   * Buffer for single encoded bits until byte is full.
   */
  uint8_t _encoded_bit_buf;

  /**
   * Current bit position in single bit buffer.
   */
  uint8_t _encoded_bit_buf_pos;

  /**
   * Write byte to output.
   *
   * Be aware that single bits written with <code>write_bit(uint8_t)</code> are
   * written to an intermediate buffer until a full byte can be flushed to the
   * output.
   *
   * @param byte  The byte to write to the output.
   */
  inline void write_byte(uint8_t byte) {
    call OutBuffer.write(byte);
    // TODO: Error if byte can't be written. This only happens on worst case
    // images though
    // TODO: Use local buffer to write to cyclic buffer in blocks -> increases
    // speed?
  }

  /**
   * Write single bit to the output.
   *
   * Bits are written to an intermediate buffer until a full byte can be flushed
   * to the output. Call <code>write_bit_flush()</code> to flush the buffer to
   * the output.
   *
   * @param bit   The bit to write to the output.
   */
  inline void write_bit(uint8_t bit) {
    --_encoded_bit_buf_pos;

    if (bit) _encoded_bit_buf |= (1 << _encoded_bit_buf_pos);

    if (_encoded_bit_buf_pos == 0) {
      write_byte(_encoded_bit_buf);
      _encoded_bit_buf = 0;
      _encoded_bit_buf_pos = 8;
    }
  }

  /**
   * Flushes the single bit buffer written with <code>write_bit(uint8_t)</code>
   * to the output even if the byte is not full yet.
   */
  inline void write_bit_flush() {
    if (_encoded_bit_buf_pos != 8) {
      write_byte(_encoded_bit_buf);
      _encoded_bit_buf = 0;
      _encoded_bit_buf_pos = 8;
    }
  }

  /**
   * Calculate <code>ceil(log2(a))</code> of a value <code>a</code>.
   *
   * @param a The input value.
   *
   * @returns The <code>ceil(log2(a))</code> of the input value <code>a</code>.
   */
  inline uint8_t ceillog2(uint16_t a) {
    uint8_t res = 0;
    --a;
    while (a) {
      a >>= 1;
      ++res;
    }
    return res;
  }

  /**
   * Binary encodes the input parameter <code>a</code> and writes the encoded
   * value to the output. Lower values are encoded with less bits.
   *
   * @param a     The input parameter.
   * @param range The range of input parameters (possible length of the binary
   * code increases with range).
   */
  inline void binary_encode(uint16_t a, uint16_t range) {
    int8_t bits = ceillog2(range);
    uint8_t thresh = (uint8_t)((1 << bits) - range);

    if (a < thresh)
      --bits;
    else
      a += thresh;

    while ((--bits) >= 0) write_bit((uint8_t)(a >> bits) & 0x1);
  }

  /**
   * Binary encodes the input parameter <code>a</code> and writes the encoded
   * value to the output. Values in the middle of the range are encoded with
   * less bits.
   *
   * @param a     The input parameter.
   * @param range The range of input parameters (possible length of the binary
   * code increases with range).
   */
  inline void adjusted_binary_encode(uint16_t a, uint16_t range) {
    int8_t bits = ceillog2(range);
    uint8_t thresh = (uint8_t)((1 << bits) - range);

    // ADJUSTED PART START ------------

    a -= ((range - thresh) >> 1);
    if ((int16_t)a < 0) a += range;

    // ADJUSTED PART END --------------

    if (a < thresh)
      --bits;
    else
      a += thresh;

    while ((--bits) >= 0) write_bit((uint8_t)(a >> bits) & 0x1);
  }

  /**
   * Unary encodes the input parameter <code>a</code> and writes the encoded
   * value to the output.
   *
   * @param a     The input parameter.
   */
  inline void unary_encode(uint16_t a) {
    while (a--) write_bit(1);
    write_bit(0);
  }

  /**
   * Golomb-rice encodes the input parameter <code>a</code> and writes the
   * encoded value to the output.
   *
   * @param a     The input parameter.
   * @param k     The parameter K of the golomb-rice code.
   */
  inline void golomb_rice_encode(uint8_t a, uint8_t k) {
    unary_encode(a >> k);
    if (k > 0) binary_encode(a & ((1 << k) - 1), 1 << k);
  }

  /**
   * Compress the next block of pixels and write them to the output.
   */
  inline void compress_block() {
    // current pixel value
    uint8_t P;
    // pixel value memory to pick the neighbors from
    //
    // ****456789...255
    // 0123P*****...255
    static uint8_t line[256];
    // neighbor pixel value 1 of current pixel
    uint8_t N1;
    // neighbor pixel value 2 of current pixel
    uint8_t N2;
    // lower neighbor pixel value of the current pixel
    uint8_t L;
    // higher neighbor pixel value of the current pixel
    uint8_t H;
    // delta between lower and higher neighbor pixel value
    uint8_t delta;
    // difference between lower/higher neighbor pixel value and the current
    // pixel value if the the current pixel lies outside the range between lower
    // and higher neighbor pixel values
    uint8_t diff;
    // row iterator
    uint16_t i = 0;

    // Check if there is enough free space in the output buffer to compress a
    // new block
    // TODO: Worst case image can produce an output that is larger than the
    // input. This would cause a buffer overflow.
    if (call OutBuffer.free() < COMPRESS_BLOCK_SIZE) return;

    // iterate over all image pixels
    do {
      do {
        // Felics Step 1:
        P = _in_buf[_in_buf_pos + i++];
        if (y > 0) {
          if (x > 0) {
            N1 = line[x - 1];
            N2 = line[x];
          } else {
            N1 = line[x];
            N2 = line[x + 1];
          }
        } else {
          if (x > 1) {
            N1 = line[x - 1];
            N2 = line[x - 2];
          } else if (x > 0) {
            N1 = line[x - 1];
            N2 = N1;
          } else {
            line[x] = P;
            write_byte(P);
            continue;
          }
        }
        line[x] = P;

        // Felics Step 2:
        if (N1 > N2) {
          H = N1;
          L = N2;
        } else {
          H = N2;
          L = N1;
        }
        delta = H - L;

        // Felics Step 3:
        if ((L <= P) && (P <= H)) {
          // Felics Step 3 (a):
          write_bit(IN_RANGE);
          if (delta > 0) adjusted_binary_encode(P - L, delta + 1);
        } else {
          // Felics Step 3 (b) or (c):
          write_bit(OUT_OF_RANGE);
          if (P < L) {
            write_bit(BELOW_RANGE);
            diff = L - P - 1;
          } else {
            write_bit(ABOVE_RANGE);
            diff = P - H - 1;
          }
          golomb_rice_encode(diff, K);
        }
      } while (x++ != 255 && i < COMPRESS_BLOCK_SIZE);
    } while (x == 0 && y++ != 255 && i < COMPRESS_BLOCK_SIZE);

    _in_buf_pos += COMPRESS_BLOCK_SIZE;
    _bytes_processed += COMPRESS_BLOCK_SIZE;
    if (_bytes_processed == 65536) write_bit_flush();
  }
#elif defined(TRUNCATE_1)
#if COMPRESS_BLOCK_SIZE % 8 != 0
#error "COMPRESS_BLOCK_SIZE has to be a multiple of 8 when using TRUNCATE_1!"
#endif
  /**
   * Compress the next block of pixels and write them to the output.
   */
  inline void compress_block() {
    uint8_t tmp[COMPRESS_BLOCK_SIZE / 8 * 7], j, sliced = 0;
    uint16_t i;
    if (call OutBuffer.free() >= sizeof(tmp)) {
      for (i = 0, j = 0; i < sizeof(tmp); i++) {
        if (j++ == 0) {
          sliced = _in_buf[_in_buf_pos + 7];
        }
        tmp[i] = _in_buf[_in_buf_pos++] & 0xFE;
        tmp[i] |= (sliced >>= 1) & 0x01;
        if (j == 7) {
          j = 0;
          _in_buf_pos++;
        }
      }
      call OutBuffer.write_block(tmp, sizeof(tmp));
      _bytes_processed += COMPRESS_BLOCK_SIZE;
    }
  }
#elif defined(TRUNCATE_2)
#if COMPRESS_BLOCK_SIZE % 4 != 0
#error "COMPRESS_BLOCK_SIZE has to be a multiple of 4 when using TRUNCATE_2!"
#endif
  /**
   * Compress the next block of pixels and write them to the output.
   */
  inline void compress_block() {
    uint8_t tmp[COMPRESS_BLOCK_SIZE / 4 * 3], j, sliced = 0;
    uint16_t i;
    if (call OutBuffer.free() >= sizeof(tmp)) {
      for (i = 0, j = 0; i < sizeof(tmp); i++) {
        if (j++ == 0) {
          sliced = _in_buf[_in_buf_pos + 3];
        }
        tmp[i] = _in_buf[_in_buf_pos++] & 0xFC;
        tmp[i] |= (sliced >>= 2) & 0x03;
        if (j == 3) {
          j = 0;
          _in_buf_pos++;
        }
      }
      call OutBuffer.write_block(tmp, sizeof(tmp));
      _bytes_processed += COMPRESS_BLOCK_SIZE;
    }
  }
#elif defined(TRUNCATE_4)
#if COMPRESS_BLOCK_SIZE % 2 != 0
#error "COMPRESS_BLOCK_SIZE has to be a multiple of 2 when using TRUNCATE_4!"
#endif
  /**
   * Compress the next block of pixels and write them to the output.
   */
  inline void compress_block() {
    uint8_t tmp[COMPRESS_BLOCK_SIZE / 2];
    uint16_t i;
    if (call OutBuffer.free() >= sizeof(tmp)) {
      for (i = 0; i < sizeof(tmp); i++) {
        tmp[i] = _in_buf[_in_buf_pos++] & 0xF0;
        tmp[i] |= _in_buf[_in_buf_pos++] >> 4;
      }
      call OutBuffer.write_block(tmp, sizeof(tmp));
      _bytes_processed += COMPRESS_BLOCK_SIZE;
    }
  }
#endif

  /**
   * Compression task.
   */
  task void compress() {
    if (_bytes_processed == 65536) {
      // Whole image compressed -> signal done
      _running = FALSE;
      signal Compression.done();
      return;
    } else if (_in_buf == NULL) {
      // No new input available. Do nothing.
    } else if (_in_buf_pos == COMPRESS_IN_BUF_SIZE) {
      // Input buffer consumed -> request a new one
      uint8_t* tmp = _in_buf;
      _in_buf_pos = 0;
      _in_buf = NULL;
      signal Compression.consumed_input(tmp);
    } else {
      // Try to compress next block
      compress_block();
    }
    // Re-post task until compression is done
    post compress();
  }

  command error_t Compression.start() {
    if (_running) {
      // compression is already running
      return EBUSY;
    } else {
      // start compression
      // reset state variables and buffers
      _running = TRUE;
      _bytes_processed = 0;
      _in_buf = NULL;
      _in_buf_pos = 0;
      call OutBuffer.clear();
#ifdef FELICS
      x = y = 0;
      _encoded_bit_buf = 0;
      _encoded_bit_buf_pos = 8;
#endif
      // start compression task
      post compress();
      return SUCCESS;
    }
  }

  command error_t Compression.new_input(uint8_t * buf) {
    if (_running == FALSE) {
      // no running compression process to provide new data for
      return ECANCEL;
    } else if (_in_buf != NULL) {
      // the current input is not consumed yet
      return EBUSY;
    } else {
      // set new input
      _in_buf = buf;
      _in_buf_pos = 0;
      return SUCCESS;
    }
  }
}