#include "Config.h"

#define WRITE_FLASH
#define READ_FLASH
#define CHECK_FIRST_BLOCK

#if (256 * 256) % COMPRESS_IN_BUF_SIZE != 0
#error "COMPRESS_IN_BUF_SIZE has to be a divider of 256*256!"
#endif

module CompressionTestC {
  uses {
    interface Leds;
    interface Boot;
    interface Flash;
    interface ProcessInput as Compression;
    interface CircularBuffer as SendBuffer;
    // 6-pin connector outer middle pin:
    interface HplMsp430GeneralIO as GIO3;
  }
}
implementation {
  uint16_t flashPos;
  uint8_t raw[COMPRESS_IN_BUF_SIZE];

#ifdef FELICS
#include "felics_test_data.h"
#else
  uint8_t testData[256] = {
      0xAA,  // 10101010
      0xFF,  // 1111111
      0xFF,  // 11111111
      0xFF,  // 11111111
      0xFF,  // 11111111
      0xFF,  // 11111111
      0xFF,  // 11111111
      0xE4   // 11100100
  };
#endif

  event void Flash.eraseDone(error_t result) {
    call Flash.writeBlock(testData, 0);
  }

  event void Flash.writeDone(uint8_t * block, error_t result) {
    call Flash.sync();
  }

  event void Flash.syncDone(error_t error) {
    flashPos = 0;
    call Compression.start();
    call Flash.readBlock(raw, flashPos);
  }

  event void Flash.readDone(uint8_t * block, error_t result) {
    call Leds.led0Off();
    call Compression.newInput(raw);
  }

  event void Compression.consumedInput(uint8_t * buf) {
    call Leds.led0On();
    flashPos += 1;

#ifdef READ_FLASH
    call Flash.readBlock(raw, flashPos);  // real flash data
#else
    call Compression.newInput(raw);  // random buffer data
    call Leds.led0Off();
#endif
  }

  event void Compression.done() {
    call Leds.set(7);
    call GIO3.clr();
  }

  task void readCompressed() {
    static uint8_t enc[512];
    static uint16_t pos = 0;
    bool t = TRUE;

    if (call SendBuffer.readBlock(enc, sizeof(enc)) == FAIL) {
      post readCompressed();
      return;
    }

#ifdef FELICS
    t = (bool)(memcmp(&testEncExpected[pos], enc, 512) == 0);
    pos += 512;

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

#ifdef CHECK_FIRST_BLOCK
    while (1) {
      if (t)
        call Leds.set(5);  // tests passed
      else
        call Leds.set(2);  // tests failed
    }
#endif

    post readCompressed();
  }

  event void Boot.booted() {
    // init
    call Leds.set(0);
    call GIO3.makeOutput();
    call GIO3.clr();

    // start compression
    call GIO3.set();
    post readCompressed();

#ifdef WRITE_FLASH
    // test with prior writing of test data to flash
    call Flash.erase();
#else
    // test with existing flash test data
    signal Flash.syncDone(SUCCESS);
#endif
  }
}