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
  /**
   * Module is currently running.
   */
  bool _running = FALSE;

  /**
   * Compression is done. Read from input buffer even if there are not enough
   * bytes available to fill a whole packet. Just fill remaining payload with
   * zeros.
   */
  bool _flush = FALSE;

  /**
   * Data packet.
   */
  message_t _pkt;

  /**
   * Counts sent packets.
   */
  uint16_t _pktCount;

  /**
   * Chunk of image date to send next.
   */
  uint8_t _chunk[RF_PAYLOAD_SIZE - 2];

  /**
   * This chunk of image data is the last.
   * (Used to notify the receiver and shut down the module etc.)
   */
  bool _last;

  /**
   * Task to send the last read chunk of data.
   */
  task void sendTask() {
    if (call AMSend.send(AM_BROADCAST_ADDR, &_pkt, sizeof(RFDataMsg_t)) !=
        SUCCESS) {
      post sendTask();
    }
  }

  /**
   * Send the last read chunk of data.
   */
  void sendChunk() {
    // prepare message
    RFDataMsg_t* m =
        (RFDataMsg_t*)call AMSend.getPayload(&_pkt, sizeof(RFDataMsg_t));
    memcpy(m->data, _chunk, sizeof(_chunk));
    m->nr = _last ? 0xFFFF : _pktCount;
    // trigger send task
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

  /**
   * Checks in buffer for new data, reads it and triggers the sending of the
   * read chunk of data.
   */
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

  /**
   * Handles received ACK messages.
   */
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
    post sendTask();
  }

  event void AMControl.startDone(error_t error) {
    if (error == SUCCESS)
      post checkBuffer();
    else
      call AMControl.start();
  }

  command error_t RFSender.send() {
    if (_running) {
      return EBUSY;
    } else {
      // Init state variables
      _running = TRUE;
      _pktCount = 0;
      _last = FALSE;
      _flush = FALSE;
      // Start the radio controller
      return call AMControl.start();
    }
  }
}