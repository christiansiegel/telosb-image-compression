#ifndef SERIALMESSAGES_H
#define SERIALMESSAGES_H

#define SERIAL_PAYLOAD_SIZE 32

typedef nx_struct SerialDataMsg {
  nx_uint8_t data[SERIAL_PAYLOAD_SIZE];
} SerialDataMsg_t;

typedef nx_struct SerialCmdMsg {
  nx_uint8_t cmd;
} SerialCmdMsg_t;

enum {
  AM_SERIALDATAMSG = 0x89,
  AM_SERIALCMDMSG = 0x90,

  CMD_FLASH_REQUEST = 0,
  CMD_FLASH_START = 1,
  CMD_FLASH_ACK = 2,
  CMD_FLASH_END = 3,
  
  CMD_RF_REQUEST = 10,
  CMD_RF_START = 11,
  CMD_RF_END = 12
};

#endif /* SERIALMESSAGES_H */
