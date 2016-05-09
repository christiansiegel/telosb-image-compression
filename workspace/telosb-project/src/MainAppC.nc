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

#ifdef SENDER
  components SenderAppC as App;

  // Compression
  components CompressionC as Compression;
  components new CircularBufferC(COMPRESSION_BUF_SIZE) as CompressionBuffer;
  
  // Sending
  components RFSenderC;

  App.Compression->Compression;
  App.RFSender->RFSenderC;

  Compression.InBuffer->FlashBuffer;
  Compression.OutBuffer->CompressionBuffer;
  
  RFSenderC.InBuffer->CompressionBuffer;
#else // RECEIVER
  // TODO
#endif

  App.Boot->MainC;
  App.Leds->LedsC;
  App.GIO3->GIO.Port26; // 6-pin connector -> outer middle pin
  
  App.FlashWriter->Flash;
  App.FlashReader->Flash;
  App.FlashBuffer->FlashBuffer;  // until we have a serial receiver module

  Flash.BlockRead->ImageStorage;
  Flash.BlockWrite->ImageStorage;
  Flash.Buffer->FlashBuffer;
  Flash.BufferLowLevel->FlashBuffer;
}