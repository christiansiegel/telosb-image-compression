#include "Defs.h"
#include "CompressionTestData.h"

module RFReceiverC {
  uses interface CircularBufferWrite as OutBuffer;
  provides interface RFReceiver;
}
implementation {
	bool _running;
  uint32_t byteCount;
  
  task void receiveTask() {
  	static uint32_t pos;
    static error_t result;

    if (byteCount >= IMAGE_SIZE) {
      // this cehck is not possible later because we don't know how many byte are sent. we have to wait for some DONE telegram.
      signal RFReceiver.receiveDone(SUCCESS);
      return;
    } else {
      // write test data to flash buffer if enough space is available
      #ifdef NO_COMPRESSION
      pos = byteCount <= sizeof(testData) ? byteCount : 0;
      result = call OutBuffer.writeBlock(&testData[pos], RF_PAYLOAD_SIZE);
      #else
      pos = byteCount <= sizeof(testEncExpected) ? byteCount : 0;
      result = call OutBuffer.writeBlock(&testEncExpected[pos], RF_PAYLOAD_SIZE);
      #endif
      
      //#ifdef FELICS
      //if(byteCount == 0)
      //  PRINT_DUMP(testEncExpected, 16);
      //#endif
      
      if (result == SUCCESS) {
      	byteCount += RF_PAYLOAD_SIZE;
      	}
    }

    post receiveTask();
  	
  	}
	
  command error_t RFReceiver.receive() { 
  if (_running) {
      return EBUSY;
    } else {
      byteCount = 0;
      _running = TRUE;
      post receiveTask();
      return SUCCESS;
    }
   }
}