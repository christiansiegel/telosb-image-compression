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
  }
  provides interface SerialControl;
}
implementation {
  /**
   * serial message
   */
  message_t _serialMsg;

  /**
   * TRUE if module waits to send to serial.
   */
  uint8_t _sending;

  /**
   * Image chunk buffer.
   */
  uint8_t _chunk[SERIAL_PAYLOAD_SIZE];

  /**
   * Init serial after boot.
   */
  event void Boot.booted() {
    _sending = FALSE;
    call AMControl.start();
  }

  event void AMControl.startDone(error_t error) {signal SerialControl.rfTransmissionOk();}

  event void AMControl.stopDone(error_t error) {}

  /**
   * Loops until it is able to send the command message.
   */
  task void retryCmdSend() {
    if (call AMCmdSend.send(AM_BROADCAST_ADDR, &_serialMsg,
                            sizeof(SerialCmdMsg_t)) != SUCCESS) {
      post retryCmdSend();
    }
  }

  /**
   * Send a command over serial.
   *
   * @param cmd the command to send
   */
  void sendCmd(uint8_t cmd) {
    SerialCmdMsg_t* m = (SerialCmdMsg_t*)call AMCmdSend.getPayload(
        &_serialMsg, sizeof(SerialCmdMsg_t));
    m->cmd = cmd;
    if (call AMCmdSend.send(AM_BROADCAST_ADDR, &_serialMsg,
                            sizeof(SerialCmdMsg_t)) != SUCCESS) {
      _sending = TRUE;
      post retryCmdSend();
    }
  }

  event void AMCmdSend.sendDone(message_t * msg, error_t error) {
    if (error == SUCCESS)
      _sending = FALSE;
    else
      post retryCmdSend();
  }

  /**
   * Loops until the module doesn't wait for the sending of something else, and
   * then issues the sending of the flash start command.
   */
  task void sendCmdFlashStart() {
    if (!_sending)
      sendCmd(CMD_FLASH_START);
    else
      post sendCmdFlashStart();
  }

  /**
   * Loops until the module doesn't wait for the sending of something else, and
   * then issues the sending of the flash end command.
   */
  task void sendCmdFlashEnd() {
    if (!_sending)
      sendCmd(CMD_FLASH_END);
    else
      post sendCmdFlashEnd();
  }

  /**
   * Loops until the module doesn't wait for the sending of something else, and
   * then issues the sending of the flash ACK command.
   */
  task void sendCmdFlashAck() {
    if (!_sending)
      sendCmd(CMD_FLASH_ACK);
    else
      post sendCmdFlashAck();
  }

  /**
   * Loops until the module doesn't wait for the sending of something else, and
   * then issues the sending of the RF start command.
   */
  task void sendCmdRfStart() {
    if (!_sending)
      sendCmd(CMD_RF_START);
    else
      post sendCmdRfStart();
  }

  /**
   * Loops until the module doesn't wait for the sending of something else, and
   * then issues the sending of the RF end command.
   */
  task void sendCmdRfEnd() {
    if (!_sending)
      sendCmd(CMD_RF_END);
    else
      post sendCmdRfEnd();
  }

  command void SerialControl.flashAccessEnd() { post sendCmdFlashEnd(); }

  command void SerialControl.rfTransmissionStart() { post sendCmdRfStart(); }

  command void SerialControl.rfTransmissionEnd() { post sendCmdRfEnd(); }

#ifdef SENDER
  /**
   * Loop until it was able to save the last received image chunk to the flash
   * buffer.
   */
  task void retrySaveChunk() {
    if (call OutBuffer.writeBlock(_chunk, sizeof(_chunk)) != SUCCESS) {
      post retrySaveChunk();
    } else {
      post sendCmdFlashAck();
    }
  }

  event message_t* AMDataReceive.receive(message_t * msg, void* payload,
                                         uint8_t len) {
    if (len == sizeof(SerialDataMsg_t)) {
      SerialDataMsg_t* m = (SerialDataMsg_t*)payload;
      memcpy(_chunk, m->data, sizeof(SerialDataMsg_t));
      post retrySaveChunk();
    }
    return msg;
  }
#else  // RECEIVER
  /**
   * Number of bytes send to the PC app.
   */
  uint32_t _byteCount;

  /**
   * Loops until it was able to send the next serial data message.
   */
  task void retryDataSend() {
    error_t result = call AMDataSend.send(AM_BROADCAST_ADDR, &_serialMsg,
                                          sizeof(SerialDataMsg_t));
    if (result != SUCCESS) post retryDataSend();
  }

  /**
   * Loops until the whole image was sent to the PC app.
   */
  task void sendImageTask() {
    if (!_sending &&
        call InBuffer.readBlock(_chunk, sizeof(SerialDataMsg_t)) == SUCCESS) {
      SerialDataMsg_t* m = (SerialDataMsg_t*)call AMDataSend.getPayload(
          &_serialMsg, sizeof(SerialDataMsg_t));
      memcpy(m->data, _chunk, sizeof(SerialDataMsg_t));
      if (call AMDataSend.send(AM_BROADCAST_ADDR, &_serialMsg,
                               sizeof(SerialDataMsg_t)) != SUCCESS) {
        _sending = TRUE;
        post retryDataSend();
      }
    } else {
      post sendImageTask();
    }
  }

  event void AMDataSend.sendDone(message_t * msg, error_t error) {
    _sending = FALSE;
    _byteCount += sizeof(SerialDataMsg_t);
    if (_byteCount >= IMAGE_SIZE) signal SerialControl.sendDone(SUCCESS);
  }
#endif

  command void SerialControl.flashAccessStart() {
    post sendCmdFlashStart();

#ifdef RECEIVER
    _byteCount = 0;
    post sendImageTask();
#endif
  }

  /**
   * Handles received commands from the PC app.
   */
  event message_t* AMCmdReceive.receive(message_t * msg, void* payload,
                                        uint8_t len) {
    if (len == sizeof(SerialCmdMsg_t)) {
      SerialCmdMsg_t* m = (SerialCmdMsg_t*)payload;
      if (m->cmd == CMD_FLASH_REQUEST) {
        signal SerialControl.flashAccessOk();
      } else if (m->cmd == CMD_RF_REQUEST) {
        signal SerialControl.rfTransmissionOk();
      }
#ifdef RECEIVER
      else if (m->cmd == CMD_FLASH_ACK) {
        post sendImageTask();
      }
#endif
    }
    return msg;
  }
}