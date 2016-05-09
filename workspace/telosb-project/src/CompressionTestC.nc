#include "Defs.h"

#define WRITE_FLASH

module CompressionTestC {
  uses {
    interface Boot;
    interface Leds;
    interface HplMsp430GeneralIO as GIO3;
    interface FlashWriter;
    interface FlashReader;
    interface Compression;
    interface CircularBufferWrite as FlashBuffer;
    interface CircularBufferRead as SendBuffer;
  }
}
implementation {
#ifdef FELICS
#include "felics_test_data.h"
#else
  uint8_t testData[256] = {
      0xAA,  // 10101010
      0xFF,  // 11111111
      0xFF,  // 11111111
      0xFF,  // 11111111
      0xFF,  // 11111111
      0xFF,  // 11111111
      0xFF,  // 11111111
      0xE4   // 11100100
  };
#endif

  task void senderTask() {
    static uint8_t enc[512];
    bool t = TRUE;
    static uint16_t blockNr = 0;

    if (call SendBuffer.available() < sizeof(enc)) {
      post senderTask();
      return;
    }

    call SendBuffer.readBlock(enc, sizeof(enc));

#ifdef FELICS
    t = (bool)(memcmp(&testEncExpected[sizeof(enc) * blockNr], enc, sizeof(enc)) == 0);
#elif defined(TRUNCATE_1)
    t &= enc[0] == 0xAA;  // 10101010
    t &= enc[1] == 0xFF;  // 11111111
    t &= enc[2] == 0xFE;  // 11111110
    t &= enc[3] == 0xFE;  // 11111110
    t &= enc[4] == 0xFF;  // 11111111
    t &= enc[5] == 0xFF;  // 11111111
    t &= enc[6] == 0xFF;  // 11111111
#elif defined(TRUNCATE_2)
    t &= enc[0] == 0xAB;  // 10101011
    t &= enc[1] == 0xFF;  // 11111111
    t &= enc[2] == 0xFF;  // 11111111

    t &= enc[3] == 0xFD;  // 11111101
    t &= enc[4] == 0xFE;  // 11111110
    t &= enc[5] == 0xFF;  // 11111111
#elif defined(TRUNCATE_4)
    t &= enc[0] == 0xAF;  // 10101111
    t &= enc[1] == 0xFF;  // 11111111
    t &= enc[2] == 0xFF;  // 11111111
    t &= enc[3] == 0xFE;  // 11111110
#endif

#ifdef FELICS
    if (blockNr < 3) {
#elif
    if (blockNr == 0) {
#endif
      PRINTLN("check of %d byte block #%d: %s", sizeof(enc), blockNr,
              t ? "PASSED" : "FAILED");
    }
    blockNr++;
    
    post senderTask();
  }

  /**
   * Temporary replacement for the serial receiver.
   */
  task void serialReceiverTask() {
    static uint32_t byteCount = 0;
    uint32_t pos;
    error_t result;

    if (byteCount >= 65536) {
      // all bytes received
      PRINTLN("simulated serial receiver done");
      return;
    } else {
      // write test data to flash buffer is enough space is available
      pos = byteCount <= sizeof(testData) ? byteCount : 0;
      result = call FlashBuffer.writeBlock(&testData[pos], SERIAL_PAYLOAD_SIZE);
      if (result == SUCCESS) byteCount += SERIAL_PAYLOAD_SIZE;
    }

    post serialReceiverTask();
  }

  event void FlashWriter.writeDone(error_t error) {
    PRINTLN("flash write done => result: %d", error);
    if (error == SUCCESS) {
      call FlashReader.read();
      call Compression.compress();
      post senderTask();
    }
  }

  event void FlashReader.readDone(error_t error) {
    PRINTLN("flash read done => result: %d", error);
  }

  event void Compression.compressDone(error_t error) {
    PRINTLN("compression done => result: %d", error);
  }

  event void Boot.booted() {
    call Leds.set(0);
    call GIO3.makeOutput();
    call GIO3.clr();

#ifdef WRITE_FLASH
    PRINTLN("test with prior writing of test data to flash...");
    post serialReceiverTask();
    call FlashWriter.write();
#else
    PRINTLN("test with existing flash test data...");
    signal FlashWriter.writeDone(SUCCESS);
#endif
  }
}