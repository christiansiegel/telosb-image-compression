#include "CompressionTestData.h"
#include "Defs.h"

module RFSenderC {
  uses interface CircularBufferRead as InBuffer;
  uses interface AMSend;
  uses interface SplitControl as AMControl;
  uses interface Packet;
  uses interface Receive as AckReceiver;
  provides interface RFSender;
}
implementation {
  bool _running;
  bool _flush;
  uint8_t _message_id;
  bool _acked;
  message_t pkt;
  static uint8_t enc[RF_PAYLOAD_SIZE];

  task void sendTask() {
		if(call AMControl.start() == SUCCESS)
		{
			reliable_msg_t* msg = (reliable_msg_t*)(call Packet.getPayload(&pkt, sizeof(reliable_msg_t)));
			//Here we set our message payload [msg->data = enc;]
			memcpy(msg->data, &enc ,sizeof(enc));
			msg->message_id = _message_id;
			_acked = FALSE;
			call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(reliable_msg_t));	
		}
	}

  task void checkBuffer() {    
		//Check the buffer status and set to the right block
		// Check if we are at the last block
    	if (_flush && (call InBuffer.available()) <= RF_PAYLOAD_SIZE ) {
    		if(_acked)
    		{
    			//Here we are supposed to read the last block of bytes
	      		//memset(enc, 0, RF_PAYLOAD_SIZE);
		 		call InBuffer.readBlock(enc, call InBuffer.available());
		 		post sendTask();
		 		signal RFSender.sendDone(SUCCESS);
		 		return;
    		}
    		//Resend previous message
    		post sendTask();	
    		return;
    	} 
    	// Normal case, send next
    	else if (call InBuffer.available() >= RF_PAYLOAD_SIZE) 
    	{
    		// We got the last message 
    		if(_acked == TRUE)
    		{
    			call InBuffer.readBlock(enc, RF_PAYLOAD_SIZE); //Here we set what we need to send in enc
				post sendTask();
			}
			else // Resend the last message
			{
				post sendTask();
			}
			return;		
    	}
    	else
    	{
			post checkBuffer();
			return;
		}
	}
		
  command error_t RFSender.send() {
    if (_running) {
		return EBUSY;
    } else {
	    _running = TRUE;
	    _flush = FALSE; //Check if needed
	    post checkBuffer();
	    return SUCCESS; //check if we finished sending the whole content?
    }
  }
  event void AMSend.sendDone(message_t *msg, error_t error){
  	if(error == SUCCESS)
  	{
  		_running = FALSE;
  		//call AMControl.stop();
  	}
  	else
  	{
  		post sendTask();
  	}
  }
  
   event void AMControl.startDone(error_t error){
   }
   
   event void AMControl.stopDone(error_t error){
   //TODO:implement stop logic
   }
   		
  command void RFSender.flush() { _flush = TRUE; }
  
  //-----------------------RECEIVING ACK--------------------------------------------------------
  
  event message_t * AckReceiver.receive(message_t *msg, void *payload, uint8_t len)
  {
  	if(len == sizeof(ack_msg_t))
  	{    
  		//TODO PROPER CHECK
  		_acked == TRUE;
  	}
   return msg;
  }
  
  
}