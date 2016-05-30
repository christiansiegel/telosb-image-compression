#include "Defs.h"

module ReceiverAppC {
  uses {
    interface Boot;
    interface Leds;
    interface HplMsp430GeneralIO as GIO3;
    interface FlashWriter;
    interface FlashReader;
    interface SerialControl as Serial;
#ifndef NO_COMPRESSION
    interface Decompression as Compression;
#endif
    interface RFReceiver as Rf;
    interface CircularBufferWrite as FlashBuffer;
  }
}
implementation {
  /**
   * Current state of the mote.
   */
  state _state = IDLE;

  /**
   * Set state.
   * Also prints message and sets leds.
   *
   * @param s   new state
   */
  void setState(state s) {
    switch (s) {
      case IDLE:
        PRINTLN("entered IDLE");
        call GIO3.clr();
        break;
      case FLASH_ACCESS:
        PRINTLN("entered FLASH_ACCESS");
        break;
      case RF_TRANSMISSION:
        PRINTLN("entered RF_TRANSMISSION");
        call GIO3.set();
        break;
      default:
        return;
    }
    _state = s;
#ifdef LEDS_SHOW_STATE
    call Leds.set((uint8_t)_state);
#endif
  }

  event void Boot.booted() {
    call GIO3.makeOutput();
    setState(IDLE);
  }

  event void Serial.flashAccessOk() {
    if (_state == IDLE) {
      setState(FLASH_ACCESS);
      call FlashReader.read();
      call Serial.flashAccessStart();
    }
  }

  event void FlashReader.readDone(error_t error) {
    PRINTLN("flash read done => result: %d", error);
  }
  
  event void Serial.sendDone(error_t error) {
  	PRINTLN("serial send done => result: %d", error);
    setState(IDLE);
    call Serial.flashAccessEnd();
  }

  event void Serial.rfTransmissionOk() {
    if (_state == IDLE) {
      setState(RF_TRANSMISSION);
      call Rf.receive();
#ifndef NO_COMPRESSION
      call Compression.decompress();
#endif
      call FlashWriter.write();

      // TODO: Maybe we should call this first, when transmission actually takes
      // place?
      call Serial.rfTransmissionStart();
    }
  }

  event void Rf.receiveDone(error_t error) {
    PRINTLN("sending done => result: %d", error);
  }

#ifndef NO_COMPRESSION
  event void Compression.decompressDone(error_t error) {
    PRINTLN("decompression done => result: %d", error);
  }
#endif

  event void FlashWriter.writeDone(error_t error) {
    PRINTLN("flash write done => result: %d", error);
    setState(IDLE);
    call Serial.rfTransmissionEnd();
  }
}