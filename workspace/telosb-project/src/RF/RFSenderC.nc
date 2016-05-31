#include "Defs.h"
#include "RFMessages.h"

module RFSenderC {
  uses {
    interface CircularBufferRead as InBuffer;
    interface AMSend;
    interface SplitControl as AMControl;
    interface Receive as AMReceive;
    interface Timer<TMilli> as TimeoutTimer;
  }
  provides interface RFSender;
}
implementation {
  bool _running = FALSE;
  bool _flush = FALSE;
  // bool _acked = TRUE;
  message_t _pkt;
  // static uint8_t enc[RF_PAYLOAD_SIZE];

  uint16_t _pktCount;
  uint8_t _chunk[RF_PAYLOAD_SIZE - 2];
  bool _last;

  task void sendTask() {
    if (call AMSend.send(AM_BROADCAST_ADDR, &_pkt, sizeof(RFDataMsg_t)) !=
        SUCCESS) {
      post sendTask();
    }
  }

  void sendChunk() {
    RFDataMsg_t* m =
        (RFDataMsg_t*)call AMSend.getPayload(&_pkt, sizeof(RFDataMsg_t));
    memcpy(m->data, _chunk, sizeof(_chunk));
    m->nr = _last ? 0xFFFF : _pktCount;
    post sendTask();
  }

  event void AMSend.sendDone(message_t * msg, error_t error) {
    if (error == SUCCESS) {
      PRINTLN("sent #%d %d", _pktCount, _last);
      call TimeoutTimer.startOneShot(ACK_TIMEOUT);
    } else {
      post sendTask();
    }
  }

  task void checkBuffer() {
    if (call InBuffer.readBlock(_chunk, sizeof(_chunk)) == SUCCESS) {
      // we were able to read a full packet from the buffer -> send it
      sendChunk();
    } else if (_flush) {
      // there is not enough data in the buffer for a whole package but we can
      // flush
      memset(_chunk, 0, sizeof(_chunk));
      call InBuffer.readBlock(_chunk, call InBuffer.available());
      _last = TRUE;
      sendChunk();
    } else {
      // nothing to send. check again later
      post checkBuffer();
    }
  }

  event void AMControl.stopDone(error_t error) {
    _running = FALSE;
    signal RFSender.sendDone(SUCCESS);
  }

  command void RFSender.flush() { _flush = TRUE; }

  //-----------------------RECEIVING
  //ACK--------------------------------------------------------

  event message_t* AMReceive.receive(message_t * msg, void* payload,
                                     uint8_t len) {
    if (len == sizeof(RFAckMsg_t)) {
      PRINTLN("ACK ");
      // We successfully sent the packet, stop the timeout timer
      call TimeoutTimer.stop();

      _pktCount++;

      if (_last) {
        // Turn of RF Module
        call AMControl.stop();
      } else {
        // Send the next packet
        post checkBuffer();
      }
    }
    return msg;
  }

  event void TimeoutTimer.fired() {
    // We never received a message so we need to retry sending
    PRINTLN("TO");
    post sendTask();
  }

  event void AMControl.startDone(error_t error) {
    PRINTLN("RF started")
    if (error == SUCCESS)
      post checkBuffer();
    else
      call AMControl.start();
  }

  command error_t RFSender.send() {
    if (_running) {
      return EBUSY;
    } else {
      _running = TRUE;
      _pktCount = 0;
      // Start the radio controller
      return call AMControl.start();
    }
  }
}