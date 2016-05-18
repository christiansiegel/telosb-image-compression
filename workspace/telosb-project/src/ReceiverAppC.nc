#include "Defs.h"

module ReceiverAppC {
  uses {
    interface Boot;
    interface Leds;
    interface HplMsp430GeneralIO as GIO3;
    interface FlashWriter;
    interface FlashReader;
    interface SerialControl as Serial;
    interface Decompression as Compression;
    interface RFReceiver as Rf;
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
  state _state;

  event void Boot.booted() {
    call Leds.set(0);
    call GIO3.makeOutput();
    call GIO3.clr();

    _state = IDLE;
    PRINTLN("entered IDLE");
  }

  event void FlashWriter.writeDone(error_t error) {
    // TODO Auto-generated method stub
  }

  event void FlashReader.readDone(error_t error) {
    // TODO Auto-generated method stub
  }

  event void Serial.flashAccessOk() {
    // TODO Auto-generated method stub
  }

  event void Serial.imageTransmissionOk() {
    // TODO Auto-generated method stub
  }

  event void Compression.decompressDone(error_t error) {
    // TODO Auto-generated method stub
  }

  event void Rf.receiveDone(error_t error) {
    // TODO Auto-generated method stub
  }
}