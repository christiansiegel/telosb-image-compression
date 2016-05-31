#ifndef RFMESSAGES_H
#define RFMESSAGES_H

#include "Config.h"

/**
 * Radio message structure. 
 */
typedef nx_struct reliable_msg {
    nx_uint8_t data[RF_PAYLOAD_SIZE];
    nx_uint16_t nr;
} reliable_msg_t;

/**
 * Ack message structure. 
 */
typedef nx_struct ack_msg {
} ack_msg_t; 

/**
 * Specifies the identifier for the Active message. Sender and receiver must use the same.
 */
enum {
  AM_TYPE = 4
};

#endif /* RFMESSAGES_H */
