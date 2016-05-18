#include "Defs.h"

/**
 * Serial module fore the receiving mote.
 */
module SerialReceiverC {
  uses {
    interface Boot;
    interface CircularBufferWrite as OutBuffer;
  }
  provides interface SerialControl;
}
implementation {
  command void SerialControl.flashAccessStart() {}
  command void SerialControl.flashAccessEnd() {}
  command void SerialControl.rfTransmissionStart() {}
  command void SerialControl.rfTransmissionEnd() {}

  event void Boot.booted() {
    // TODO Auto-generated method stub
  }
}