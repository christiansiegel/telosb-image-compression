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
  /**
   * X-coordinate of currently processed pixel.
   */
  uint8_t x;

  /**
   * Y-coordinate of currently processed pixel.
   */
  uint8_t y;

  /**
   * Buffer for single encoded bits until new byte is read.
   */
  uint8_t _bitBuf;

  /**
   * Current bit position in single bit buffer.
   */
  uint8_t _bitBufPos;

  /**
   * Reads byte from circular buffer.
   * Attention: If @see readBit() is used be aware that it reads a whole byte
   * and stores it in @see _bitBuf.
   */
  inline uint8_t readByte() {
    static uint8_t byte;
    // TODO: if returns FAIL we get an invalid byte!! Only the case on worst
    // case images.
    call InBuffer.read(&byte);
    return byte;
  }

  /**
   * Reads bit from @see _bitBuf and fetches a new byte from circular buffer if
   * bit buffer was read completely.
   */
  inline uint8_t readBit() {
    if (_bitBufPos == 0) {
      _bitBuf = readByte();
      _bitBufPos = 8;
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
    static uint8_t res;
    res = 0;
    --a;
    while (a) {
      a >>= 1;
      ++res;
    }
    return res;
  }

  /**
   * Binary decodes the next byte from the input buffer and returns the decoded
   * value.
   *
   * @param range The range of input parameters (possible length of the binary
   * code increases with range).
   * @returns The decoded byte.
   */
  inline uint8_t binaryDecode(uint16_t range) {
    static uint8_t bits, thresh, i;
    static uint16_t a;

    bits = ceillog2(range);
    thresh = (uint8_t)((1 << bits) - range);

    a = 0;
    for (i = 0; i < bits - 1; i++) a += a + readBit();

    if (a >= thresh) {
      a += a + readBit();
      a -= thresh;
    }

    return (uint8_t)a;
  }

  /**
   * Binary decodes the next byte from the input buffer and returns the decoded
   * value. Values in the middle of the range are encoded with less bits.
   *
   * @param range The range of input parameters (possible length of the binary
   * code increases with range).
   * @returns The decoded byte.
   */
  inline uint8_t adjustedBinaryDecode(uint16_t range) {
    static uint8_t bits, thresh, i;
    static uint16_t a;

    bits = ceillog2(range);
    thresh = (uint8_t)((1 << bits) - range);

    a = 0;
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
   * Unary decodes the next byte from the input buffer and returns the decoded
   * value.
   *
   * @returns The decoded byte.
   */
  inline uint16_t unaryDecode() {
    static uint16_t a;
    a = 0;
    while (readBit()) ++a;
    return a;
  }

  /**
   * Golomb-rice decodes the next byte from the input buffer and returns the
   * decoded value.
   *
   * @param k     The parameter K of the golomb-rice code.
   * @returns The decoded byte.
   */
  inline uint8_t golombRiceDecode(uint8_t k) {
    static uint8_t a;
    a = (uint8_t)(unaryDecode() << k);
    if (k > 0) a |= binaryDecode(1 << k);
    return a;
  }

  /**
   * Decompress the next block of pixels and write them to the output buffer.
   */
  inline void decompressBlock() {
    // current pixel value
    static uint8_t P;
    // pixel value memory to pick the neighbors from
    //
    // ****456789...255
    // 0123P*****...255
    static uint8_t line[256];
    // neighbor pixel value 1 of current pixel
    static uint8_t N1;
    // neighbor pixel value 2 of current pixel
    static uint8_t N2;
    // lower neighbor pixel value of the current pixel
    static uint8_t L;
    // higher neighbor pixel value of the current pixel
    static uint8_t H;
    // delta between lower and higher neighbor pixel value
    static uint8_t delta;
    // difference between lower/higher neighbor pixel value and the current
    // pixel value if the the current pixel lies outside the range between lower
    // and higher neighbor pixel values
    static uint8_t diff;
    static uint8_t flag;
    // pixel iterator for this block
    static uint16_t i;

    // Check if there is enough available data in the input buffer to decode a
    // block.
    // TODO: Worst case image can use an input that is larger than the
    // output. This would cause the readByte() to read a faulty byte.
    if (call InBuffer.available() < COMPRESS_BLOCK_SIZE) return;

    // iterate over all image pixels
    i = 0;
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
            call OutBuffer.write(P);
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
        call OutBuffer.write(P);
      } while (x++ != 255 && i < COMPRESS_BLOCK_SIZE);
    } while (x == 0 && y++ != 255 && i < COMPRESS_BLOCK_SIZE);

    _bytesProcessed += COMPRESS_BLOCK_SIZE;
  }
#elif defined(TRUNCATE_1)
#if COMPRESS_BLOCK_SIZE % 8 != 0
#error "COMPRESS_BLOCK_SIZE has to be a multiple of 8 when using TRUNCATE_1!"
#endif
  /**
   * Decompress the next block of pixels and write them to the output buffer.
   */
  inline void decompressBlock() {
    static uint8_t j, sliced;
    static uint8_t tmpIn[COMPRESS_BLOCK_SIZE / 8 * 7];
    static uint8_t tmpOut[COMPRESS_BLOCK_SIZE];
    static uint16_t iOut, iIn;
    if (call InBuffer.readBlock(tmpIn, sizeof(tmpIn)) == SUCCESS) {
      for (iIn = iOut = 0; iOut < COMPRESS_BLOCK_SIZE;) {
        sliced = 0;
        for (j = 0; j < 7; j++, iIn++) {
          tmpOut[iOut++] = tmpIn[iIn] & 0xFE;
          sliced |= (tmpIn[iIn] & 0x01) << (j + 1);
        }
        tmpOut[iOut++] = sliced;
      }
      call OutBuffer.writeBlock(tmpOut, COMPRESS_BLOCK_SIZE);
      _bytesProcessed += COMPRESS_BLOCK_SIZE;
    }
  }
#elif defined(TRUNCATE_2)
#if COMPRESS_BLOCK_SIZE % 4 != 0
#error "COMPRESS_BLOCK_SIZE has to be a multiple of 4 when using TRUNCATE_2!"
#endif
  /**
   * Decompress the next block of pixels and write them to the output buffer.
   */
  inline void decompressBlock() {
    static uint8_t j, sliced;
    static uint8_t tmpIn[COMPRESS_BLOCK_SIZE / 4 * 3];
    static uint8_t tmpOut[COMPRESS_BLOCK_SIZE];
    static uint16_t iOut, iIn;
    if (call InBuffer.readBlock(tmpIn, sizeof(tmpIn)) == SUCCESS) {
      for (iIn = iOut = 0; iOut < COMPRESS_BLOCK_SIZE;) {
        sliced = 0;
        for (j = 0; j < 3; j++, iIn++) {
          tmpOut[iOut++] = tmpIn[iIn] & 0xFC;
          sliced |= (tmpIn[iIn] & 0x03) << 2 * (j + 1);
        }
        tmpOut[iOut++] = sliced;
      }
      call OutBuffer.writeBlock(tmpOut, COMPRESS_BLOCK_SIZE);
      _bytesProcessed += COMPRESS_BLOCK_SIZE;
    }
  }
#elif defined(TRUNCATE_4)
#if COMPRESS_BLOCK_SIZE % 2 != 0
#error "COMPRESS_BLOCK_SIZE has to be a multiple of 2 when using TRUNCATE_4!"
#endif
  /**
   * Decompress the next block of pixels and write them to the output buffer.
   */
  inline void decompressBlock() {
    static uint8_t tmpIn[COMPRESS_BLOCK_SIZE / 2];
    static uint8_t tmpOut[COMPRESS_BLOCK_SIZE];
    static uint16_t iOut, iIn;

    if (call InBuffer.readBlock(tmpIn, sizeof(tmpIn)) == SUCCESS) {
      for (iIn = iOut = 0; iOut < COMPRESS_BLOCK_SIZE; iIn++) {
        tmpOut[iOut++] = tmpIn[iIn] & 0xF0;
        tmpOut[iOut++] = tmpIn[iIn] << 4;
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
    // Re-post task until decompression is done
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
      // start decompression task
      post decompressTask();
      return SUCCESS;
    }
  }
}