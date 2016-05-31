#ifndef RFMESSAGES_H
#define RFMESSAGES_H

#include "Config.h"

/**
 * Radio message structure.
 */
typedef nx_struct RFDataMsg {
  nx_uint8_t data[RF_PAYLOAD_SIZE - 2];
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

  ACK_TIMEOUT = 1000
};

#endif /* RFMESSAGES_H */