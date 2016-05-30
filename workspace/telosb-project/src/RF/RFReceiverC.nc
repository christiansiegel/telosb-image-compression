#include "Defs.h"
#include "CompressionTestData.h"

module RFReceiverC 
{
  	uses interface CircularBufferWrite as OutBuffer;
  	uses interface AMSend;
  	uses interface SplitControl as AMControl;
  	uses interface Packet;
  	uses interface AMPacket;
 	uses interface Receive; 
 	uses interface Leds;
  	provides interface RFReceiver;
}
implementation 
{
 	bool _running;
  	uint32_t byteCount;
  	message_t pkt;
  	uint8_t* LastReceivedData;
  
  	task void receiveTask() 
  	{
    	static error_t result;
    	// If we have loaded the image
	    if (byteCount >= IMAGE_SIZE)
	  	{
	      // this check is not possible later because we don't know how many byte are sent. we have to wait for some DONE telegram.
	      signal RFReceiver.receiveDone(SUCCESS);
	      return;
		}
      	else // Start the image loading and control start 
      	{	
      		
		    // update the bytecount if we succesfully wrote a block
      		if (result == SUCCESS)
      		{
      			// Get the payload for the ack message
      			ack_msg_t* ReceivedPacket = (ack_msg_t*)call Packet.getPayload(&pkt, sizeof(ack_msg_t));
      			// Send an ack message
      			if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(ack_msg_t))== SUCCESS)
      			{
      				// Load the data into memory
      				byteCount += RF_PAYLOAD_SIZE;
      				
		      		// Write a block on the buffer
		      		result = call OutBuffer.writeBlock(LastReceivedData, RF_PAYLOAD_SIZE);
		      		call Leds.led2Toggle();
      			}
      		}
    	}
    	// Schedule a new receive
    	post receiveTask();
  	}
	
  	command error_t RFReceiver.receive() 
  	{ 
		if (_running)
	  	{
	  		// We are busy
	      	return EBUSY;
	    } 
	    else 
	    {
    		// Set the initial state 
      		byteCount = 0;
	      	_running = TRUE;
	      	
      		// Start the controller
      		call AMControl.start();
	      	// Schedule the image receive
	      	post receiveTask();
	      	return SUCCESS;
	    }
   	}
  
	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len)
	{
		//Receive packet if we have enough space
	  	if(call OutBuffer.free() >= RF_PAYLOAD_SIZE)
	  	{
	  		if(len == sizeof(reliable_msg_t))
	  		{
	  			//pkt = (reliable_msg_t*)payload;
	  			
      			reliable_msg_t* ReceivedPacket = (reliable_msg_t*)call Packet.getPayload(&pkt, sizeof(reliable_msg_t));
	  			LastReceivedData = ReceivedPacket->data;
	  			call Leds.led1Toggle();
	  		}
	  	}
	  	return msg;
  	}
  	
    event void AMControl.startDone(error_t error)
    {
    }
    event void AMControl.stopDone(error_t error)
    {
    		
    }
  

	event void AMSend.sendDone(message_t *msg, error_t error)
	{
		// TODO Auto-generated method stub
	}

}