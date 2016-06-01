#ifndef RFMESSAGES_H
#define RFMESSAGES_H

#include "Config.h"

/**
 * Radio message structure.
 */
typedef nx_struct RFDataMsg {
  /**
   * Chunk of compressed image data.
   */
  nx_uint8_t data[RF_PAYLOAD_SIZE - 2];
  /**
   * Packet counter starting from 0. The last packet is marked with a number of
   * 0xFFFF.
   */
  nx_uint16_t nr;
}
RFDataMsg_t;

/**
 * Ack message structure.
 */
typedef nx_struct RFAckMsg {}
RFAckMsg_t;

enum {
  AM_RFDATAMSG = 4,
  AM_RFACKMSG = 5,

  ACK_TIMEOUT = 100
};

#endif /* RFMESSAGES_H */