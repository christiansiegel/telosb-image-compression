#include "Defs.h"
#include "RFMessages.h"

module RFReceiverC {
  uses {
    interface CircularBufferWrite as OutBuffer;
    interface AMSend;
    interface SplitControl as AMControl;
    interface Packet;
    interface AMPacket;
    interface Receive as AMReceive;
    interface Leds;
  }
  provides interface RFReceiver;
}
implementation {
  /**
   * Module is currently running.
   */
  bool _running;

  /**
   * Counts received packet.
   * (Used to drop packets that are received twice.)
   */
  uint16_t _pktCount;

  /**
   * Last received chunk of data.
   */
  uint8_t _chunk[RF_PAYLOAD_SIZE - 2];

  /**
   * Module is currently handling a received packet (writing to buffer and
   * sending ACK).
   * (Used to drop packets that are received during this period.)
   */
  bool _handling;

  /**
   * The last received packet was the last message of the transmission.
   * (Used to finish receiving after this one is acknowledged.)
   */
  bool _last;

  command error_t RFReceiver.receive() {
    if (_running) {
      return EBUSY;
    } else {
      // Set the initial state
      _pktCount = 0;
      _running = TRUE;
      _handling = FALSE;
      _last = FALSE;

      // Start the RF module
      return call AMControl.start();
    }
  }

  /**
   * Sends ACK for last received packet.
   */
  task void sendAck() {
    static message_t _pkt;
    call AMSend.getPayload(&_pkt, sizeof(RFAckMsg_t));
    if (call AMSend.send(AM_BROADCAST_ADDR, &_pkt, sizeof(RFAckMsg_t)) !=
        SUCCESS) {
      post sendAck();
    }
  }

  /**
   * Saves last received packet to buffer.
   * Triggers sending of ACK after saving.
   */
  task void saveTask() {
    if (call OutBuffer.writeBlock(_chunk, sizeof(_chunk)) == SUCCESS) {
      post sendAck();
    } else {
      post saveTask();
    }
  }

  /**
   * Handles received data packet.
   */
  event message_t* AMReceive.receive(message_t * msg, void* payload,
                                     uint8_t len) {
    if (_handling) {
      // We are currently handling a received message so just drop this one.
      return msg;
    }

    if (len == sizeof(RFDataMsg_t)) {
      RFDataMsg_t* m = (RFDataMsg_t*)payload;
      _handling = TRUE;

      PRINTLN("pkt #%u", m->nr);

      if (m->nr < _pktCount) {
        // We already handled this message. So our ACK got lost. Just re-ACK.
        post sendAck();
        return msg;
      }

      if (m->nr == 0xFFFF) {
        // This is the last message. Remember this to shut down afterwards.
        _last = TRUE;
      }

      memcpy(_chunk, m->data, sizeof(_chunk));
      _pktCount++;
      post saveTask();
    }
    return msg;
  }

  event void AMControl.startDone(error_t error) {}

  event void AMControl.stopDone(error_t error) {
    _running = FALSE;
    signal RFReceiver.receiveDone(error);
  }

  event void AMSend.sendDone(message_t * msg, error_t error) {
    if (error == SUCCESS) {
      _handling = FALSE;
      if (_last) call AMControl.stop();
    } else {
      post sendAck();
    }
  }
}