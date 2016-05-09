#include "Defs.h"
#include "CompressionTestData.h"

//#define WRITE_FLASH

module SenderAppC {
  uses {
    interface Boot;
    interface Leds;
    interface HplMsp430GeneralIO as GIO3;
    interface FlashWriter;
    interface FlashReader;
    interface Compression;
    interface RFSender;
    interface CircularBufferWrite as FlashBuffer;
  }
}
implementation {
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
      call RFSender.send();
    }
  }

  event void FlashReader.readDone(error_t error) {
    PRINTLN("flash read done => result: %d", error);
  }

  event void Compression.compressDone(error_t error) {
    PRINTLN("compression done => result: %d", error);
    call RFSender.flush();
  }

  event void RFSender.sendDone(error_t error) {
    PRINTLN("sending done => result: %d", error);
  }

  event void Boot.booted() {
    call Leds.set(7);
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