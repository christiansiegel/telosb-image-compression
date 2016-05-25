#include "CompressionTestData.h"
#include "Defs.h"

#include "SerialMessages.h"
/**
 * Serial module.
 */
module SerialModuleC {
	uses {
		interface Boot;
		interface SplitControl as AMControl;
		interface AMSend as AMCmdSend;
		interface Receive as AMCmdReceive;
		#ifdef SENDER 
		interface CircularBufferWrite as OutBuffer;
		interface Receive as AMDataReceive;
		#else
		interface CircularBufferRead as InBuffer;
		interface AMSend as AMDataSend;
		#endif
		interface Leds;
	}
	provides interface SerialControl;
}
implementation {
	message_t _serialMsg;
    uint8_t _sending;
    uint8_t _chunk[SERIAL_PAYLOAD_SIZE];
	
	// init serial after boot
	event void Boot.booted() {
		_sending = FALSE;
		call AMControl.start();
	}

	event void AMControl.startDone(error_t error) {
	}
	
	event void AMControl.stopDone(error_t error) {
	}

    task void retryCmdSend() {
        if(call AMCmdSend.send(AM_BROADCAST_ADDR, &_serialMsg, sizeof(SerialCmdMsg_t)) != SUCCESS)
            post retryCmdSend();
    }
  
    void sendCmd(uint8_t cmd) {
        SerialCmdMsg_t* m = (SerialCmdMsg_t*)call AMCmdSend.getPayload(&_serialMsg, sizeof(SerialCmdMsg_t));
        m->cmd = cmd;
        if(call AMCmdSend.send(AM_BROADCAST_ADDR, &_serialMsg, sizeof(SerialCmdMsg_t)) != SUCCESS) {
        	_sending = TRUE;
            post retryCmdSend();  
        }
    }

	event void AMCmdSend.sendDone(message_t * msg, error_t error) {
		if(error == SUCCESS) _sending = FALSE;
        else post retryCmdSend();
	}
	
	task void sendCmdFlashStart() {
        if(!_sending) sendCmd(CMD_FLASH_START);
        else post sendCmdFlashStart();
    }
    
    task void sendCmdFlashEnd() {
        if(!_sending) sendCmd(CMD_FLASH_END);
        else post sendCmdFlashEnd();
    }
    
    task void sendCmdFlashAck() {
        if(!_sending) sendCmd(CMD_FLASH_ACK);
        else post sendCmdFlashAck();
    }
    
    task void sendCmdRfStart() {
        if(!_sending) sendCmd(CMD_RF_START);
        else post sendCmdRfStart();
    }
    
    task void sendCmdRfEnd() {
        if(!_sending) sendCmd(CMD_RF_END);
        else post sendCmdRfEnd();
    }

	command void SerialControl.flashAccessEnd() {
		post sendCmdFlashEnd();
	}

	command void SerialControl.rfTransmissionStart() {
		post sendCmdRfStart();
	}

	command void SerialControl.rfTransmissionEnd() {
		post sendCmdRfEnd();
	}

	// handles received commands from the PC app
	event message_t * AMCmdReceive.receive(message_t * msg, void * payload, uint8_t len) {
		if(len == sizeof(SerialCmdMsg_t)) {
			SerialCmdMsg_t * m = (SerialCmdMsg_t * ) payload;
			if(m->cmd == CMD_FLASH_REQUEST) {
				signal SerialControl.flashAccessOk();
			}
			else if(m->cmd == CMD_RF_REQUEST) {
				signal SerialControl.rfTransmissionOk();
			}
		}
		return msg;
	}

#ifdef SENDER
	task void retrySaveChunk() {
		if(call OutBuffer.writeBlock(_chunk, sizeof(_chunk)) != SUCCESS) {
			post retrySaveChunk();
		} else {
            call Leds.led2Toggle();
            post sendCmdFlashAck();	
		}
	}

	event message_t * AMDataReceive.receive(message_t * msg, void * payload,
			uint8_t len) {
		if(len == sizeof(SerialDataMsg_t)) {
			memcpy(payload, _chunk, sizeof(SerialDataMsg_t));
            post retrySaveChunk();    
		}
		return msg;
	}
#else // RECEIVER
    message_t _serialDataMsg;

    task void retryDataSend() {
        if(call AMDataSend.send(AM_BROADCAST_ADDR, &_serialDataMsg, sizeof(SerialDataMsg_t)) != SUCCESS)
            post retryDataSend();
    }

	void sendData() {
		SerialDataMsg_t* m = (SerialDataMsg_t*)call AMDataSend.getPayload(&_serialDataMsg, sizeof(SerialDataMsg_t));
        memcpy(_chunk, m->data, sizeof(SerialDataMsg_t));
        if(call AMDataSend.send(AM_BROADCAST_ADDR, &_serialDataMsg, sizeof(SerialDataMsg_t)) != SUCCESS) {
            _sending = TRUE;
            post retryDataSend();  
        }
	}
	
	task void sendImageTask() {
		if(_sending) {
			post sendImageTask();
		} else if(call InBuffer.readBlock(_chunk, sizeof(_chunk)) == SUCCESS) {
			sendData();
		} else { 
			post sendImageTask();
		}
	}

	event void AMDataSend.sendDone(message_t * msg, error_t error) {
		_sending = FALSE;
		post sendImageTask();
	}
	#endif

	command void SerialControl.flashAccessStart() {
		post sendCmdFlashStart();
#ifdef RECEIVER
		post sendImageTask();
#endif
	}
}