#include "CompressionTestData.h"
#include "Defs.h"

module RFSenderC {
  uses interface CircularBufferRead as InBuffer;
  provides interface RFSender;
}
implementation {
  bool _running;
  bool _flush;
  uint16_t blockNr;

  task void sendTask() {
    static uint8_t enc[RF_PAYLOAD_SIZE];
    bool t = TRUE;

    if (_flush) {
      memset(enc, 0, RF_PAYLOAD_SIZE);
      call InBuffer.readBlock(enc, call InBuffer.available());
    } else if (call InBuffer.available() >= RF_PAYLOAD_SIZE) {
      call InBuffer.readBlock(enc, RF_PAYLOAD_SIZE);
    } else {
      post sendTask();
      return;
    }

// instead of sending just check compressed data:

#ifdef FELICS
    t = (bool)(memcmp(&testEncExpected[RF_PAYLOAD_SIZE * blockNr], enc,
                      RF_PAYLOAD_SIZE) == 0);
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
    if (blockNr < 10) {
#else
    if (blockNr == 0) {
#endif
        PRINTLN("check of %d byte block #%d: %s", sizeof(enc), blockNr,
                t ? "PASSED" : "FAILED");
      }
    blockNr++;

    // this would go into the sendDone event handler of the RF module:
    if (_flush) {
      _running = FALSE;
      signal RFSender.sendDone(SUCCESS);
      return;
    } else {
      post sendTask();
    }
  }

  command error_t RFSender.send() {
    if (_running) {
      return EBUSY;
    } else {
      blockNr = 0;
      _running = TRUE;
      _flush = FALSE;
      post sendTask();
      return SUCCESS;
    }
  }

  command void RFSender.flush() { _flush = TRUE; }
}