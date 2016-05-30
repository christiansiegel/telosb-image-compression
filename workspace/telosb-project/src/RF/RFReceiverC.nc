#include "Defs.h"
#include "CompressionTestData.h"

module RFReceiverC {
  uses interface CircularBufferWrite as OutBuffer;
  uses interface Receive;
  provides interface RFReceiver;
}
implementation {
  bool _running;
  uint32_t byteCount;
  reliable_msg_t* pkt;
  
  
  task void receiveTask() {
  	static uint32_t pos;
    static error_t result;
    

    if (byteCount >= IMAGE_SIZE) {
      // this check is not possible later because we don't know how many byte are sent. we have to wait for some DONE telegram.
      signal RFReceiver.receiveDone(SUCCESS);
      return;
    } else {
      // write test data to flash buffer if enough space is available
      /*
      #ifdef NO_COMPRESSION
      pos = byteCount <= sizeof(testData) ? byteCount : 0;
      result = call OutBuffer.writeBlock(&testData[pos], RF_PAYLOAD_SIZE);
      #else
      pos = byteCount <= sizeof(testEncExpected) ? byteCount : 0;
      result = call OutBuffer.writeBlock(&testEncExpected[pos], RF_PAYLOAD_SIZE);
      #endif
      */
      nx_uint16_t* data = pkt->data;
      pos = byteCount <= sizeof(&data) ? byteCount : 0;
      result = call OutBuffer.writeBlock(data[pos], RF_PAYLOAD_SIZE);
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
  
  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
  	if(len == sizeof(reliable_msg_t)){
  		pkt = (reliable_msg_t*)payload;
  		}
  	
  	return msg;
  	}
}