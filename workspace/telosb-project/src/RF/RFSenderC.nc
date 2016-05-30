#include "CompressionTestData.h"
#include "Defs.h"

module RFSenderC {
  uses interface CircularBufferRead as InBuffer;
  uses interface AMSend;
  uses interface SplitControl as AMControl;
  uses interface PacketAcknowledgements as Ack;
  provides interface RFSender;
}
implementation {
  bool _running;
  bool _flush;
  bool _wait_ack = FALSE; //Used to stop sending if no ack is received for the package previously sent
  message_t pkt;

  task void sendTask() {
    static uint8_t enc[RF_PAYLOAD_SIZE];
    
    
		//Check the buffer status and set to the right block
    	if (_flush) {
      		memset(enc, 0, RF_PAYLOAD_SIZE);
      		call InBuffer.readBlock(enc, call InBuffer.available());
      		call RFSender.send();
    	} else if (call InBuffer.available() >= RF_PAYLOAD_SIZE) {
    		call InBuffer.readBlock(enc, RF_PAYLOAD_SIZE);
    		call AMControl.start();
			reliable_msg_t* msg = (reliable_msg_t*)call AMSend.getPayload(&pkt, sizeof(reliable_msg_t));
			msg->data = enc;
			call Ack.requestAck(msg); //set a flag in the header, asking for synchronous ack
			call AMSend.send(AM_BROADCAST_ADDR, msg, sizeof(reliable_msg_t));
    	}else{
    		post sendTask();
    		return;
    		}
		}
   
/**
    
    // this would go into the sendDone event handler of the RF module:
    if (_flush) {
      _running = FALSE;
      signal RFSender.sendDone(SUCCESS);
      return;
    } else {
      post sendTask();
    }
*/  

  command error_t RFSender.send() {
    if (_running) {
		return EBUSY;
    } else {
	    _running = TRUE;
	    _flush = FALSE;
	    post sendTask();
	    return SUCCESS;
    }
  }
  event void AMSend.sendDone(message_t *msg, error_t error){
  	if(call Ack.wasAcked(msg) && error == SUCCESS){
  		_running = FALSE;
  		call AMControl.stop();
  		signal RFSender.sendDone(SUCCESS);
  	}else{
  		post sendTask(); //or just try sending again?
  		}
  }
   event void AMControl.startDone(error_t error){
   //TODO:implement start logic	
   }
   
   event void AMControl.stopDone(error_t error){
   //TODO:implement stop logic
   }
   		
  command void RFSender.flush() { _flush = TRUE; }
}