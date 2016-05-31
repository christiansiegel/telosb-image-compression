#include "CompressionTestData.h"
#include "Defs.h"

module RFSenderC {
  uses interface CircularBufferRead as InBuffer;
  uses interface AMSend;
  uses interface SplitControl as AMControl;
  uses interface Packet;
  uses interface Receive as AckReceiver;
  uses interface Timer<TMilli> as TimeoutTimer;
  provides interface RFSender;
}
implementation 
{
	bool _running = FALSE;
	bool _flush = FALSE;
	bool _acked = TRUE;
	message_t pkt;
  	static uint8_t enc[RF_PAYLOAD_SIZE];

  	task void SendTask() 
  	{
  		reliable_msg_t* msg = NULL;
  		uint8_t result=0;
		msg = (reliable_msg_t*)(call Packet.getPayload(&pkt, sizeof(reliable_msg_t)));
		//Here we set our message payload [msg->data = enc;]
		memcpy(msg->data, enc ,sizeof(enc));
		_acked = FALSE;
		
		// Send the message
		result = call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(reliable_msg_t));
		if(result != SUCCESS)
		{
			post SendTask();	
		}
	}

	task void CheckBuffer() 
	{   
		// Check the buffer status and set to the right block
		// Check if we are at the last block
    	if (_flush && (call InBuffer.available()) <= RF_PAYLOAD_SIZE ) 
    	{
    		// Try to load the next message
			PRINTLN("last");
			//Read the last block of bytes
	 		call InBuffer.readBlock(enc, call InBuffer.available());
	 		// Send message
    		post SendTask();
	 		signal RFSender.sendDone(SUCCESS);
    	}
    	// Normal case, send next
    	if (call InBuffer.available() >= RF_PAYLOAD_SIZE) 
    	{
    		// Try to load the next message
			PRINTLN(" next ");
			call InBuffer.readBlock(enc, RF_PAYLOAD_SIZE); //Here we set what we need to send in enc			
			post SendTask();
    	}
    	// Nothing is ready yet, just reschedule a buffer check
    	else
    	{
    		PRINTLN("Not Ready");
			post CheckBuffer();
		}
		
		
	}
		
  	command error_t RFSender.send() 
 	{
	    if (_running) 
	    {
			return EBUSY;
	    } 
	    else 
	    {
		    _running = TRUE;
		    // Start the radio controller
		    return call AMControl.start();
	    }
  	}
  
  	event void AMSend.sendDone(message_t *msg, error_t error)
  	{
	   	if(error == SUCCESS)
	  	{
	  		// Start the ack timer
			call TimeoutTimer.startOneShot(Ack_Timeout_Period);
	  	}
	  	else
	  	{
	  		post SendTask();
	  	}
	  	
    }
  
   	event void AMControl.startDone(error_t error)
   	{
   		post CheckBuffer();
   	}
   
   	event void AMControl.stopDone(error_t error)
   	{
   	}
   		
  	command void RFSender.flush() { _flush = TRUE; }
  
  	//-----------------------RECEIVING ACK--------------------------------------------------------
  
  	event message_t * AckReceiver.receive(message_t *msg, void *payload, uint8_t len)
  	{
	  	// Is there a message
	  	if(len != 0)
	  	{
	  		// Is it an ack message
		  	ack_msg_t* Message = (ack_msg_t*) call Packet.getPayload(&pkt, sizeof(ack_msg_t));
		  	if(Message != NULL)
		  	{    
		  		PRINTLN("ACKRECEIVER: Ack received");
		  		_acked = TRUE;
		  		// We successfully sent the packet, stop the timeout timer
		  		call TimeoutTimer.stop();
		  		post CheckBuffer();
		  	}
  		}
	    return msg;
  	}

	event void TimeoutTimer.fired()
	{		
		PRINTLN("TO");
		// We never received a message so we need to retry sending
  		_acked = FALSE;
		post SendTask();		
	}
}