#include "StorageVolumes.h"
#include "Defs.h"
#include "SerialMessages.h"
#include "RFMessages.h"

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

  // Serial
  components SerialModuleC as Serial;
  components SerialActiveMessageC;
  components new SerialAMSenderC(AM_SERIALCMDMSG) as SerialCmdSender;
  components new SerialAMReceiverC(AM_SERIALCMDMSG) as SerialCmdReceiver;

#ifdef SENDER  // -------------------------------
  components SenderAppC as App;
  components new SerialAMReceiverC(AM_SERIALDATAMSG) as SerialDataReceiver;
  components RFSenderC as Rf;
  components new AMSenderC(AM_RFDATAMSG);
  components new AMReceiverC(AM_RFACKMSG);
  components ActiveMessageC;
  components new TimerMilliC() as Timer0;
#ifndef NO_COMPRESSION
  components CompressionC as Compression;
#endif

  Serial.AMDataReceive->SerialDataReceiver;
  Serial.OutBuffer->FlashBuffer;
#ifdef NO_COMPRESSION
  Rf.InBuffer->FlashBuffer;
#else
  Compression.InBuffer->FlashBuffer;
  Compression.OutBuffer->CompressionBuffer;
  Rf.InBuffer->CompressionBuffer;
#endif
  Rf.AMControl->ActiveMessageC;
  Rf.AMSend->AMSenderC;
  Rf.AMReceive->AMReceiverC;
  Rf.TimeoutTimer->Timer0.Timer;
  
#else  // RECEIVER ------------------------------
  components ReceiverAppC as App;
  components new SerialAMSenderC(AM_SERIALDATAMSG) as SerialDataSender;
  components new AMReceiverC(AM_RFDATAMSG);
  components new AMSenderC(AM_RFACKMSG);
  components ActiveMessageC;
  components RFReceiverC as Rf;
#ifndef NO_COMPRESSION
  components DecompressionC as Compression;
#endif

  Serial.AMDataSend->SerialDataSender;
  Serial.InBuffer->FlashBuffer;
#ifdef NO_COMPRESSION
  Rf.OutBuffer->FlashBuffer;
#else
  Rf.OutBuffer->CompressionBuffer;
  Compression.InBuffer->CompressionBuffer;
  Compression.OutBuffer->FlashBuffer;
#endif
  Rf.AMControl->ActiveMessageC;
  Rf.AMSend->AMSenderC;
  Rf.AMReceive->AMReceiverC;

#endif  // --------------------------------------

  App.Boot->MainC;
  App.Leds->LedsC;
  App.GIO3->GIO.Port26;  // 6-pin connector -> outer middle pin

  App.FlashWriter->Flash;
  App.FlashReader->Flash;

  App.Serial->Serial;
#ifndef NO_COMPRESSION
  App.Compression->Compression;
#endif
  App.Rf->Rf;

  Serial.AMControl->SerialActiveMessageC;
  Serial.AMCmdSend->SerialCmdSender;
  Serial.AMCmdReceive->SerialCmdReceiver;
  Serial.Boot->MainC;

  Flash.BlockRead->ImageStorage;
  Flash.BlockWrite->ImageStorage;
  Flash.BufferLowLevel->FlashBuffer;
  Flash.Buffer->FlashBuffer;
}