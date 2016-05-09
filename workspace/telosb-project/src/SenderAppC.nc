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
    interface SerialControl;
    interface Compression;
    interface RFSender;
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

  event void FlashWriter.writeDone(error_t error) {
    PRINTLN("flash write done => result: %d", error);
    _state = IDLE;
    PRINTLN("entered IDLE");
    call SerialControl.flashAccessEnd();

    // simulate received commands
    signal SerialControl.imageTransmissionOk();
  }

  event void FlashReader.readDone(error_t error) {
    PRINTLN("flash read done => result: %d", error);
  }

  event void Compression.compressDone(error_t error) {
    PRINTLN("compression done => result: %d", error);
    call RFSender.flush();
  }

  event void RFSender.sendDone(error_t error) {
    PRINTLN("sending done => result: %d", error);
    _state = IDLE;
    PRINTLN("entered IDLE");
    call SerialControl.rfTransmissionEnd();
  }

  event void SerialControl.flashAccessOk() {
    if (_state == IDLE) {
    	PRINTLN("entered FLASH_ACCESS");
      _state = FLASH_ACCESS;
      call FlashWriter.write();
      call SerialControl.flashAccessStart();
    }
  }

  event void SerialControl.imageTransmissionOk() {
    if (_state == IDLE) {
    	PRINTLN("entered RF_TRANSMISSION");
      _state = RF_TRANSMISSION;
      call FlashReader.read();
      call Compression.compress();
      call RFSender.send();
      call SerialControl.rfTransmissionStart();
    }
  }

  event void Boot.booted() {
    call Leds.set(0);
    call GIO3.makeOutput();
    call GIO3.clr();

    _state = IDLE;
    PRINTLN("entered IDLE");

// simulate received commands
#ifdef WRITE_FLASH
    PRINTLN("test with prior writing of test data to flash...");
    signal SerialControl.flashAccessOk();
#else
    PRINTLN("test with existing flash test data...");
    signal SerialControl.imageTransmissionOk();
#endif
  }
}