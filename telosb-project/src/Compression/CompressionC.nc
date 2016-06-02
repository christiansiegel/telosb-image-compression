#include "Defs.h"

/**
 * Compression of a 256x256 pixel greyscale image.
 */
module CompressionC {
  provides interface Compression;
  uses {
    interface CircularBufferWrite as OutBuffer;
    interface CircularBufferRead as InBuffer;
  }
}
implementation {
  /**
   * Compression is running.
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
   * Buffer for single encoded bits until byte is full.
   */
  uint8_t _bitBuf;

  /**
   * Current bit position in single bit buffer.
   */
  uint8_t _bitBufPos;

  /**
   * Write byte to output.
   *
   * Be aware that single bits written with <code>writeBit(uint8_t)</code> are
   * written to an intermediate buffer until a full byte can be flushed to the
   * output.
   *
   * @param byte  The byte to write to the output.
   */
  inline void writeByte(uint8_t byte) {
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
   * to the output. Call <code>writeBitFlush()</code> to flush the buffer to
   * the output.
   *
   * @param bit   The bit to write to the output.
   */
  inline void writeBit(uint8_t bit) {
    --_bitBufPos;

    if (bit) _bitBuf |= (1 << _bitBufPos);

    if (_bitBufPos == 0) {
      writeByte(_bitBuf);
      _bitBuf = 0;
      _bitBufPos = 8;
    }
  }

  /**
   * Flushes the single bit buffer written with <code>writeBit(uint8_t)</code>
   * to the output even if the byte is not full yet.
   */
  inline void writeBitFlush() {
    if (_bitBufPos != 8) {
      writeByte(_bitBuf);
      _bitBuf = 0;
      _bitBufPos = 8;
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
   * Binary encodes the input parameter <code>a</code> and writes the encoded
   * value to the output. Lower values are encoded with less bits.
   *
   * @param a     The input parameter.
   * @param range The range of input parameters (possible length of the binary
   * code increases with range).
   */
  inline void binaryEncode(uint16_t a, uint16_t range) {
    static int8_t bits;
    static uint8_t thresh;

    bits = ceillog2(range);
    thresh = (uint8_t)((1 << bits) - range);

    if (a < thresh)
      --bits;
    else
      a += thresh;

    while ((--bits) >= 0) writeBit((uint8_t)(a >> bits) & 0x1);
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
  inline void adjustedBinaryEncode(uint16_t a, uint16_t range) {
    static int8_t bits;
    static uint8_t thresh;

    bits = ceillog2(range);
    thresh = (uint8_t)((1 << bits) - range);

    // ADJUSTED PART START ------------
    a -= ((range - thresh) >> 1);
    if ((int16_t)a < 0) a += range;
    // ADJUSTED PART END --------------

    if (a < thresh)
      --bits;
    else
      a += thresh;

    while ((--bits) >= 0) writeBit((uint8_t)(a >> bits) & 0x1);
  }

  /**
   * Unary encodes the input parameter <code>a</code> and writes the encoded
   * value to the output.
   *
   * @param a     The input parameter.
   */
  inline void unaryEncode(uint16_t a) {
    while (a--) writeBit(1);
    writeBit(0);
  }

  /**
   * Golomb-rice encodes the input parameter <code>a</code> and writes the
   * encoded value to the output.
   *
   * @param a     The input parameter.
   * @param k     The parameter K of the golomb-rice code.
   */
  inline void golombRiceEncode(uint8_t a, uint8_t k) {
    unaryEncode(a >> k);
    if (k > 0) binaryEncode(a & ((1 << k) - 1), 1 << k);
  }

  /**
   * Compress the next block of pixels and write them to the output.
   */
  inline void compressBlock() {
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
    // pixel iterator for this block
    static uint16_t i;
    // temporary input buffer for this compression block
    static uint8_t tmpIn[COMPRESS_BLOCK_SIZE];

    // Check if there is enough free space in the output buffer to compress a
    // new block
    // TODO: Worst case image can produce an output that is larger than the
    // input. This would cause a loss of bytes..
    if (call OutBuffer.free() < COMPRESS_BLOCK_SIZE) return;
    if (call InBuffer.readBlock(tmpIn, COMPRESS_BLOCK_SIZE) != SUCCESS) return;

    // iterate over all image pixels
    i = 0;
    do {
      do {
        // Felics Step 1:
        P = tmpIn[i++];
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
            writeByte(P);
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
          writeBit(IN_RANGE);
          if (delta > 0) adjustedBinaryEncode(P - L, delta + 1);
        } else {
          // Felics Step 3 (b) or (c):
          writeBit(OUT_OF_RANGE);
          if (P < L) {
            writeBit(BELOW_RANGE);
            diff = L - P - 1;
          } else {
            writeBit(ABOVE_RANGE);
            diff = P - H - 1;
          }
          golombRiceEncode(diff, K);
        }
      } while (x++ != 255 && i < COMPRESS_BLOCK_SIZE);
    } while (x == 0 && y++ != 255 && i < COMPRESS_BLOCK_SIZE);

    _bytesProcessed += COMPRESS_BLOCK_SIZE;
    if (_bytesProcessed == IMAGE_SIZE) writeBitFlush();
  }
#elif defined(TRUNCATE_1)
#if COMPRESS_BLOCK_SIZE % 8 != 0
#error "COMPRESS_BLOCK_SIZE has to be a multiple of 8 when using TRUNCATE_1!"
#endif
  /**
   * Compress the next block of pixels and write them to the output.
   */
  inline void compressBlock() {
    static uint8_t j, sliced;
    static uint8_t tmpIn[COMPRESS_BLOCK_SIZE];
    static uint8_t tmpOut[COMPRESS_BLOCK_SIZE / 8 * 7];
    static uint16_t iOut, iIn;
    if (call OutBuffer.free() < sizeof(tmpOut)) return;
    if (call InBuffer.readBlock(tmpIn, COMPRESS_BLOCK_SIZE) != SUCCESS) return;
    for (iIn = iOut = 0; iIn < COMPRESS_BLOCK_SIZE; iIn++) {
      sliced = tmpIn[iIn + 7];
      for (j = 0; j < 7; j++, iIn++, iOut++) {
        tmpOut[iOut] = tmpIn[iIn] & 0xFE;
        tmpOut[iOut] |= (sliced >>= 1) & 0x01;
      }
    }
    call OutBuffer.writeBlock(tmpOut, sizeof(tmpOut));
    _bytesProcessed += COMPRESS_BLOCK_SIZE;
  }
#elif defined(TRUNCATE_2)
#if COMPRESS_BLOCK_SIZE % 4 != 0
#error "COMPRESS_BLOCK_SIZE has to be a multiple of 4 when using TRUNCATE_2!"
#endif
  /**
   * Compress the next block of pixels and write them to the output.
   */
  inline void compressBlock() {
    static int8_t j, sliced;
    static uint8_t tmpIn[COMPRESS_BLOCK_SIZE];
    static uint8_t tmpOut[COMPRESS_BLOCK_SIZE / 4 * 3];
    static uint16_t iOut, iIn;
    if (call OutBuffer.free() < sizeof(tmpOut)) return;
    if (call InBuffer.readBlock(tmpIn, COMPRESS_BLOCK_SIZE) != SUCCESS) return;
    for (iIn = iOut = 0; iIn < COMPRESS_BLOCK_SIZE; iIn++) {
      sliced = tmpIn[iIn + 3];
      for (j = 0; j < 3; j++, iIn++, iOut++) {
        tmpOut[iOut] = tmpIn[iIn] & 0xFC;
        tmpOut[iOut] |= (sliced >>= 2) & 0x03;
      }
    }
    call OutBuffer.writeBlock(tmpOut, sizeof(tmpOut));
    _bytesProcessed += COMPRESS_BLOCK_SIZE;
  }
#elif defined(TRUNCATE_4)
#if COMPRESS_BLOCK_SIZE % 2 != 0
#error "COMPRESS_BLOCK_SIZE has to be a multiple of 2 when using TRUNCATE_4!"
#endif
  /**
   * Compress the next block of pixels and write them to the output.
   */
  inline void compressBlock() {
    static uint8_t tmpIn[COMPRESS_BLOCK_SIZE];
    static uint8_t tmpOut[COMPRESS_BLOCK_SIZE / 2];
    static uint16_t iOut, iIn;
    if (call OutBuffer.free() < sizeof(tmpOut)) return;
    call InBuffer.readBlock(tmpIn, COMPRESS_BLOCK_SIZE);
    for (iIn = iOut = 0; iIn < COMPRESS_BLOCK_SIZE; iOut++) {
      tmpOut[iOut] = tmpIn[iIn++] & 0xF0;
      tmpOut[iOut] |= tmpIn[iIn++] >> 4;
    }
    call OutBuffer.writeBlock(tmpOut, sizeof(tmpOut));
    _bytesProcessed += COMPRESS_BLOCK_SIZE;
  }
#endif

  /**
   * Compression task.
   */
  task void compressTask() {
    if (_bytesProcessed == IMAGE_SIZE) {
      // Whole image compressed -> signal done
      _running = FALSE;
      signal Compression.compressDone(SUCCESS);
      return;
    } else if (call InBuffer.available() >= COMPRESS_BLOCK_SIZE) {
      // Compress next block
      // (Check if enough space in output buffer is done in compressBlock())
      compressBlock();
    }
    // Re-post task until compression is done
    post compressTask();
  }

  command error_t Compression.compress() {
    if (_running) {
      // compression is already running
      return EBUSY;
    } else {
      // start compression
      // reset state variables and buffers
      _running = TRUE;
      _bytesProcessed = 0;

      call OutBuffer.clear();
#ifdef FELICS
      x = y = 0;
      _bitBuf = 0;
      _bitBufPos = 8;
#endif
      // start compression task
      post compressTask();
      return SUCCESS;
    }
  }
}