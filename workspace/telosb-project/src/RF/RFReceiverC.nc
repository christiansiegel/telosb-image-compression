#include "Defs.h"

module RFReceiverC {
  uses interface CircularBufferRead as OutBuffer;
  provides interface RFReceiver;
}
implementation {
  command error_t RFReceiver.receive() { return FAIL; }
}