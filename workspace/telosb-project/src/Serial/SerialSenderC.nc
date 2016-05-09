#include "CompressionTestData.h"
#include "Defs.h"

/**
 * Serial module fore the sending mote.
 */
module SerialSenderC {
  uses interface CircularBufferWrite as OutBuffer;
  provides interface SerialControl;
}
implementation {
  uint32_t byteCount;

  task void serialReceiverTask() {
    uint32_t pos;
    error_t result;

    if (byteCount >= IMAGE_SIZE) {
      // all bytes received
      PRINTLN("simulated serial receiver done");
      return;
    } else {
      // write test data to flash buffer if enough space is available
      pos = byteCount <= sizeof(testData) ? byteCount : 0;
      result = call OutBuffer.writeBlock(&testData[pos], SERIAL_PAYLOAD_SIZE);
      if (result == SUCCESS) byteCount += SERIAL_PAYLOAD_SIZE;
    }

    post serialReceiverTask();
  }

  command void SerialControl.flashAccessStart() {
    byteCount = 0;
    post serialReceiverTask();
  }
  command void SerialControl.flashAccessEnd() {}
  command void SerialControl.rfTransmissionStart() {}
  command void SerialControl.rfTransmissionEnd() {}
}