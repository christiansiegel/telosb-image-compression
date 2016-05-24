#ifndef SERIALMESSAGES_H
#define SERIALMESSAGES_H

// mig java -target=telosb -I%T/lib/oski -java-classname=SerialDataMsg SerialMessages.h serial_data_msg -o SerialDataMsg.java
// mig java -target=telosb -I%T/lib/oski -java-classname=SerialCmdMsg SerialMessages.h serial_cmd_msg -o SerialCmdMsg.java
// javac *.java
// java SerialComm -comm serial@/dev/ttyUSB0:telosb

typedef nx_struct serial_data_msg {
  nx_uint8_t data[128];
} serial_data_msg_t;

typedef nx_struct serial_cmd_msg {
  nx_uint8_t cmd;
} serial_cmd_msg_t;

enum {
  AM_SERIAL_DATA_MSG = 0x89,
  AM_SERIAL_CMD_MSG = 0x90
};

#endif /* SERIALMESSAGES_H */
