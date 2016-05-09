#include "Defs.h"
#include "CompressionTestData.h"

#define WRITE_FLASH

module SenderAppC {
  uses {
    interface Boot;
    interface Leds;
    interface HplMsp430GeneralIO as GIO3;
    interface FlashWriter;
    interface FlashReader;
    interface SerialControl as Serial;
    interface Compression;
    interface RFSender as Rf;
    interface CircularBufferWrite as FlashBuffer;
  }
}
implementation {
  enum States {
    /**
     * Waiting for new commands from the control PC.
     */
    IDLE,
    /**
     * PC accesses flash.
     */
    FLASH_ACCESS,
    /**
     * Motes2mote transmission.
     */
    RF_TRANSMISSION
  };
  typedef enum States state;

  /**
   * Current state of the mote.
   */
  state _state = IDLE;

  event void FlashWriter.writeDone(error_t error) {
    PRINTLN("flash write done => result: %d", error);
    _state = IDLE;
    PRINTLN("entered IDLE");
    call Serial.flashAccessEnd();
  }

  event void FlashReader.readDone(error_t error) {
    PRINTLN("flash read done => result: %d", error);
  }

  event void Compression.compressDone(error_t error) {
    PRINTLN("compression done => result: %d", error);
    call Rf.flush();
  }

  event void Rf.sendDone(error_t error) {
    PRINTLN("sending done => result: %d", error);
    _state = IDLE;
    PRINTLN("entered IDLE");
    call Serial.rfTransmissionEnd();
  }

  event void Serial.flashAccessOk() {
    if (_state == IDLE) {
    	PRINTLN("entered FLASH_ACCESS");
      _state = FLASH_ACCESS;
      call FlashWriter.write();
      call Serial.flashAccessStart();
    }
  }

  event void Serial.imageTransmissionOk() {
    if (_state == IDLE) {
    	PRINTLN("entered RF_TRANSMISSION");
      _state = RF_TRANSMISSION;
      call FlashReader.read();
      call Compression.compress();
      call Rf.send();
      call Serial.rfTransmissionStart();
    }
  }

  event void Boot.booted() {
    call Leds.set(0);
    call GIO3.makeOutput();
    call GIO3.clr();
  }
}