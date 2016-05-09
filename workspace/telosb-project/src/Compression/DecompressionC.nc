#include "Defs.h"

/**
 * Decompression of a 256x256 pixel greyscale image.
 */
module DecompressionC {
  provides interface Decompression;
  uses {
    interface CircularBufferWrite as OutBuffer;
    interface CircularBufferRead as InBuffer;
  }
}
implementation {
  /**
   * Decompression is running.
   */
  bool _running;

  /**
   * Number of processed bytes.
   */
  uint32_t _bytesProcessed;

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
  uint8_t _bitBuf;

  /**
   * Current bit position in single bit buffer.
   */
  uint8_t _bitBufPos;

  /**
 * Reads byte from @see m_encoded_buf and
 * increases @see m_encoded_buf_pos to next byte
 * position.
 * Attention: If @see read_bit() is used be aware
 *            that it reads a whole byte and stores
 *            it in @see m_encoded_bit_buf.
 */
  inline uint8_t readByte() {
    uint8_t byte;
    // TODO if returns FAIL we get an invalid byte!!
    call InBuffer.read(&byte);
    return byte;
  }

  /**
  * Reads bit from @see m_encoded_bit_buf and
  * fetches a new byte from @see m_encoded_buf if
  * bit buffer was read completely.
  */
  inline uint8_t readBit() {
    if (_bitBuf == 0) {
      _bitBuf = readByte();
      _bitBuf = 8;
    }
    return (_bitBuf >> --_bitBufPos) & 1;
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

  inline uint8_t binaryDecode(uint16_t range)  // range = 2..256
  {
    uint8_t bits = ceillog2(range);
    uint8_t thresh = (uint8_t)((1 << bits) - range);

    uint16_t a = 0;
    uint8_t i;
    for (i = 0; i < bits - 1; i++) a += a + readBit();

    if (a >= thresh) {
      a += a + readBit();
      a -= thresh;
    }

    return (uint8_t)a;
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
  inline uint8_t adjustedBinaryDecode(uint16_t range)  // range = 2..256
  {
    uint8_t bits = ceillog2(range);
    uint8_t thresh = (uint8_t)((1 << bits) - range);

    uint16_t a = 0;
    uint8_t i;
    for (i = 0; i < bits - 1; i++) a += a + readBit();

    if (a >= thresh) {
      a += a + readBit();
      a -= thresh;
    }

    // ADJUSTED PART START ------------

    a += ((range - thresh) >> 1);
    if ((int16_t)a >= range) a -= range;

    // ADJUSTED PART END --------------

    return (uint8_t)a;
  }

  /**
   * Unary encodes the input parameter <code>a</code> and writes the encoded
   * value to the output.
   *
   * @param a     The input parameter.
   */
  inline uint16_t unaryDecode() {
    uint16_t a = 0;
    while (readBit()) ++a;
    return a;
  }

  /**
   * Golomb-rice encodes the input parameter <code>a</code> and writes the
   * encoded value to the output.
   *
   * @param a     The input parameter.
   * @param k     The parameter K of the golomb-rice code.
   */
  inline uint8_t golombRiceDecode(uint8_t k) {
    uint8_t a;
    a = (uint8_t)(unaryDecode() << k);
    if (k > 0) a |= binaryDecode(1 << k);
    return a;
  }

  /**
   * Compress the next block of pixels and write them to the output.
   */
  inline void decompressBlock() {
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
    uint8_t flag;
    // pixel iterator for this block
    uint16_t i = 0;

    // Check if there is enough available data in the input buffer to decode a
    // block.
    // TODO: Worst case image can use an input that is larger than the
    // output. This would cause the readByte() to loop until data is available.
    if (call InBuffer.available() < COMPRESS_BLOCK_SIZE) return;

    // iterate over all image pixels
    do {
      do {
        i++;
        // Felics Step 1:
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
            line[x] = P = readByte();
            _outBuf[_outBufPos++] = P;
            continue;
          }
        }

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
        if (readBit() == IN_RANGE) {
          P = delta > 0 ? adjustedBinaryDecode(delta + 1) + L : L;
        } else {
          flag = readBit();
          diff = golombRiceDecode(K);
          if (flag == BELOW_RANGE)
            P = L - diff - 1;
          else
            P = diff + H + 1;
        }
        line[x] = P;
        _outBuf[_outBufPos++] = P;
      } while (x++ != 255 && i < COMPRESS_BLOCK_SIZE);
    } while (x == 0 && y++ != 255 && i < COMPRESS_BLOCK_SIZE);

    _bytesProcessed += COMPRESS_BLOCK_SIZE;
  }
#elif defined(TRUNCATE_1)
#if COMPRESS_BLOCK_SIZE % 8 != 0
#error "COMPRESS_BLOCK_SIZE has to be a multiple of 8 when using TRUNCATE_1!"
#endif
  /**
   * Compress the next block of pixels and write them to the output.
   */
  inline void decompressBlock() {
    uint8_t tmp[COMPRESS_BLOCK_SIZE / 8 * 7], j, sliced = 0;
    uint16_t i;
    if (call InBuffer.readBlock(tmp, sizeof(tmp)) == SUCCESS) {
      for (i = 0; i < sizeof(tmp);) {
        sliced = 0;
        for (j = 0; j < 7; j++, i++) {
          _outBuf[_outBufPos++] = tmp[i] & 0xFE;
          sliced |= (tmp[i] & 0x01) << (j + 1);
        }
        _outBuf[_outBufPos++] = sliced;
      }
      _bytesProcessed += COMPRESS_BLOCK_SIZE;
    }
  }
#elif defined(TRUNCATE_2)
#if COMPRESS_BLOCK_SIZE % 4 != 0
#error "COMPRESS_BLOCK_SIZE has to be a multiple of 4 when using TRUNCATE_2!"
#endif
  /**
   * Compress the next block of pixels and write them to the output.
   */
  inline void decompressBlock() {
    uint8_t tmp[COMPRESS_BLOCK_SIZE / 4 * 3], j, sliced;
    uint16_t i;
    if (call InBuffer.readBlock(tmp, sizeof(tmp)) == SUCCESS) {
      for (i = 0; i < sizeof(tmp);) {
        sliced = 0;
        for (j = 0; j < 3; j++, i++) {
          _outBuf[_outBufPos++] = tmp[i] & 0xFC;
          sliced |= (tmp[i] & 0x03) << 2 * (j + 1);
        }
        _outBuf[_outBufPos++] = sliced;
      }
      _bytesProcessed += COMPRESS_BLOCK_SIZE;
    }
  }
#elif defined(TRUNCATE_4)
#if COMPRESS_BLOCK_SIZE % 2 != 0
#error "COMPRESS_BLOCK_SIZE has to be a multiple of 2 when using TRUNCATE_4!"
#endif
  /**
   * Decompress the next block of pixels and write them to the output.
   */
  inline void decompressBlock() {
    uint8_t tmpIn[COMPRESS_BLOCK_SIZE / 2];
    uint8_t tmpOut[COMPRESS_BLOCK_SIZE];
    uint16_t iOut, iIn;
    if (call InBuffer.readBlock(tmpIn, sizeof(tmpIn) == SUCCESS) {
      for (iIn = 0, iOut = 0; iOut < COMPRESS_BLOCK_SIZE; iIn++) {
        tmpOut[iIn++] = iIn[iIn] & 0xF0;
        tmpOut[iIn++] = iIn[iIn] << 4;
      }
      call OutBuffer.writeBlock(tmpOut, COMPRESS_BLOCK_SIZE);
      _bytesProcessed += COMPRESS_BLOCK_SIZE;
    }
  }
#endif

  /**
   * Deompression task.
   */
  task void decompressTask() {
    if (_bytesProcessed == IMAGE_SIZE) {
      // Whole image decompressed -> signal done
      _running = FALSE;
      signal Decompression.decompressDone(SUCCESS);
      return;
    } else if (call OutBuffer.free() >= COMPRESS_BLOCK_SIZE) {
      // Decompress next block
      // (Check if enough data in input buffer is done in decompressBlock())
      decompressBlock();
    }
    // Re-post task until compression is done
    post decompressTask();
  }

  command error_t Decompression.decompress() {
    if (_running) {
      // decompression is already running
      return EBUSY;
    } else {
      // start decompression
      // reset state variables and buffers
      _running = TRUE;
      _bytesProcessed = 0;
      
      call OutBuffer.clear();
#ifdef FELICS
      x = y = 0;
      _bitBuf = 0;
      _bitBufPos = 0;
#endif
      // start compression task
      post decompressTask();
      return SUCCESS;
    }
  }
}