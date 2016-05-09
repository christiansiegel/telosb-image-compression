#include "StorageVolumes.h"
#include "Defs.h"

configuration MainAppC {}
implementation {
  components CompressionTestC as TestApp;

  // General
  components MainC;

  // IO
  components LedsC;
  components HplMsp430GeneralIOC as GIO;

  // Flash
  components new BlockStorageC(IMAGE_STORAGE) as ImageStorage;
  components new FlashC(IMAGE_SIZE) as Flash;
  components new CircularBufferC(FLASH_BUF_SIZE) as FlashBuffer;

  // Compression
  components CompressionC as Compression;
  components new CircularBufferC(COMPRESSION_BUF_SIZE) as CompressionBuffer;
  
  // Sending
  components RFSenderC;

  TestApp.Boot->MainC;
  TestApp.Leds->LedsC;
  TestApp.GIO3->GIO.Port26; // 6-pin connector -> outer middle pin
  TestApp.FlashWriter->Flash;
  TestApp.FlashReader->Flash;
  TestApp.Compression->Compression;
  TestApp.RFSender->RFSenderC;
  TestApp.FlashBuffer->FlashBuffer;  // until we have a serial receiver module

  Flash.BlockRead->ImageStorage;
  Flash.BlockWrite->ImageStorage;
  Flash.Buffer->FlashBuffer;
  Flash.BufferLowLevel->FlashBuffer;

  Compression.InBuffer->FlashBuffer;
  Compression.OutBuffer->CompressionBuffer;
  
  RFSenderC.InBuffer->CompressionBuffer;
}