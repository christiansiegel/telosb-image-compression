#include "Defs.h"

module SenderAppC {
  uses {
    interface Boot;
    interface Leds;
    interface HplMsp430GeneralIO as GIO3;
    interface FlashWriter;
    interface FlashReader;
    interface SerialControl as Serial;
#ifndef NO_COMPRESSION
    interface Compression;
#endif
    interface RFSender as Rf;
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
      call FlashWriter.write();
      call Serial.flashAccessStart();
    }
  }

  event void FlashWriter.writeDone(error_t error) {
    PRINTLN("flash write done => result: %d", error);
    setState(IDLE);
    call Serial.flashAccessEnd();
  }

  event void Serial.rfTransmissionOk() {
    if (_state == IDLE) {
      setState(RF_TRANSMISSION);
      call FlashReader.read();
#ifndef NO_COMPRESSION
      call Compression.compress();
#endif
      call Rf.send();
      call Serial.rfTransmissionStart();
    }
  }

  event void FlashReader.readDone(error_t error) {
    PRINTLN("flash read done => result: %d", error);
#ifdef NO_COMPRESSION
    call Rf.flush();
#endif
  }

#ifndef NO_COMPRESSION
  event void Compression.compressDone(error_t error) {
    PRINTLN("compression done => result: %d", error);
    call Rf.flush();
  }
#endif

  event void Rf.sendDone(error_t error) {
    PRINTLN("sending done => result: %d", error);
    setState(IDLE);
    call Serial.rfTransmissionEnd();
  }
}