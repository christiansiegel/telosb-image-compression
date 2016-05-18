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
    static int t;

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
    if (blockNr < 10) {
#else
    if (blockNr == 0) {
#endif
#ifndef NO_COMPRESSION
      t = memcmp(&testEncExpected[RF_PAYLOAD_SIZE * blockNr], enc, RF_PAYLOAD_SIZE);
      PRINTLN("check of %d byte block #%d: %s", sizeof(enc), blockNr,
              (t == 0) ? "PASSED" : "FAILED");
#endif
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