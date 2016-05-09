#include "StorageVolumes.h"
#include "Defs.h"

configuration MainAppC {}
implementation {
  // General
  components MainC;

  // IO
  components LedsC;
  components HplMsp430GeneralIOC as GIO;

  // Flash
  components new BlockStorageC(IMAGE_STORAGE) as ImageStorage;
  components new FlashC(IMAGE_SIZE) as Flash;
  components new CircularBufferC(FLASH_BUF_SIZE) as FlashBuffer;
  
  //(De-)Compression
  components new CircularBufferC(COMPRESSION_BUF_SIZE) as CompressionBuffer;

#ifdef SENDER
  components SenderAppC as App;
  components SerialSenderC as Serial;
  components CompressionC as Compression;
  components RFSenderC as Rf;

  Serial.OutBuffer->FlashBuffer;
  Compression.InBuffer->FlashBuffer;
  Compression.OutBuffer->CompressionBuffer;
  Rf.InBuffer->CompressionBuffer;
#else // RECEIVER
  components ReceiverAppC as App;
  components SerialReceiverC as Serial;
  components DecompressionC as Compression;
  components RFReceiverC as Rf;

  Serial.InBuffer->FlashBuffer;
  Rf.OutBuffer->CompressionBuffer;
  Compression.InBuffer->CompressionBuffer;
  Compression.OutBuffer->FlashBuffer;
#endif

  App.Boot->MainC;
  
  App.Leds->LedsC;
  App.GIO3->GIO.Port26; // 6-pin connector -> outer middle pin
  
  App.FlashWriter->Flash;
  App.FlashReader->Flash;
  
  App.Serial->Serial;
  App.Compression->Compression;
  App.Rf->Rf;

  Flash.BlockRead->ImageStorage;
  Flash.BlockWrite->ImageStorage;
  Flash.BufferLowLevel->FlashBuffer;
  Flash.Buffer->FlashBuffer;
}