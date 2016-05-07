#include "StorageVolumes.h"
#include "Config.h"

configuration MainAppC {}
implementation {
  components MainC;
  components LedsC;
  components CompressionTestC;
  components new FlashC(COMPRESS_IN_BUF_SIZE) as Flash;
  components new BlockStorageC(0);
  components CompressionC;
  components new CircularBufferC(SEND_IN_BUF_SIZE) as SendBuffer;
  components HplMsp430GeneralIOC;

  Flash.BlockRead->BlockStorageC.BlockRead;
  Flash.BlockWrite->BlockStorageC.BlockWrite;
  CompressionTestC.Boot->MainC.Boot;
  CompressionTestC.GIO3->HplMsp430GeneralIOC.Port26;
  CompressionTestC.Leds->LedsC.Leds;
  CompressionTestC.Flash->Flash;
  CompressionTestC.Compression->CompressionC;
  CompressionTestC.SendBuffer->SendBuffer;
  CompressionC.OutBuffer->SendBuffer;
}