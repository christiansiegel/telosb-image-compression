#include "Defs.h"
#include "CompressionTestData.h"

/**
 * Serial module fore the receiving mote.
 */
module SerialReceiverC {
  uses {
    interface Boot;
    interface CircularBufferRead as InBuffer;
  }
  provides interface SerialControl;
}
implementation {
 bool _running;
  uint16_t blockNr;
  
 task void sendTask() {
    static uint8_t enc[SERIAL_PAYLOAD_SIZE];
    static bool t;
    static uint16_t i;

    if (blockNr*SERIAL_PAYLOAD_SIZE >= IMAGE_SIZE) {
      PRINTLN("simulated serial transmission done");
      return;
    } else if (call InBuffer.available() >= SERIAL_PAYLOAD_SIZE) {
      call InBuffer.readBlock(enc, SERIAL_PAYLOAD_SIZE);
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
       t = TRUE;
  #if defined(FELICS)
      for(i = 0; i < SERIAL_PAYLOAD_SIZE; ++i)
          t &= enc[i] == testData[(SERIAL_PAYLOAD_SIZE * blockNr) + i];
   #elif defined(TRUNCATE_1)
      for(i = 0; i < 8; ++i)
          t &= enc[i] == (testData[i] & 0xFE);
   #elif defined(TRUNCATE_2)
      for(i = 0; i < 8; ++i)
          t &= enc[i] == (testData[i] & 0xFC);
  #elif defined(TRUNCATE_4)
      for(i = 0; i < 8; ++i)
          t &= enc[i] == (testData[i] & 0xF0);
  #endif

      PRINTLN("check of %d byte block #%d: %s", sizeof(enc), blockNr,
              t ? "PASSED" : "FAILED");
              
      //PRINT_DUMP(enc, 16);     
    }
    blockNr++;

    post sendTask();
  }

  command void SerialControl.flashAccessStart() {post sendTask();}
  command void SerialControl.flashAccessEnd() {}
  command void SerialControl.rfTransmissionStart() {}
  command void SerialControl.rfTransmissionEnd() {
  	//simulate received command
  	signal SerialControl.flashAccessOk();
  	}

  event void Boot.booted() {
    // simulate received commands
    signal SerialControl.rfTransmissionOk();
  }
}