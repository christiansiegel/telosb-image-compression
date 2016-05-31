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
  Serial.AMControl->SerialActiveMessageC; 
  Serial.AMCmdSend->SerialCmdSender;
  Serial.AMCmdReceive->SerialCmdReceiver;
  
#ifdef SENDER // -------------------------------
  components SenderAppC as App;
  components new SerialAMReceiverC(AM_SERIALDATAMSG) as SerialDataReceiver;
  
  components RFSenderC as Rf;
  components new AMSenderC(AM_TYPE);
  components new AMReceiverC(AM_TYPE);
  components ActiveMessageC;
  components new TimerMilliC() as Timer0;
    
  Serial.AMDataReceive->SerialDataReceiver;
  
  //Define the wiring to the generic interfaces 
  Rf.AMSend->AMSenderC;
  Rf.Packet->AMSenderC;
  Rf.AMControl->ActiveMessageC;
  Rf.AckReceiver-> AMReceiverC;
  Rf.TimeoutTimer -> Timer0.Timer;
  
#ifndef NO_COMPRESSION
  components CompressionC as Compression;
#endif
  //components RFSenderC as Rf;

  Serial.OutBuffer->FlashBuffer;
#ifdef NO_COMPRESSION
  Rf.InBuffer->FlashBuffer;
#else
  Compression.InBuffer->FlashBuffer;
  Compression.OutBuffer->CompressionBuffer;
  Rf.InBuffer->CompressionBuffer;
  //Rf->PacketAcknowledgements; //Added for acks working on a lower networking layer
#endif
#else // RECEIVER ------------------------------
  components ReceiverAppC as App;
  components new SerialAMSenderC(AM_SERIALDATAMSG) as SerialDataSender;
  
  components new AMReceiverC(AM_TYPE);
  components new AMSenderC(AM_TYPE);
  components ActiveMessageC;
  
  Serial.AMDataSend->SerialDataSender;
#ifndef NO_COMPRESSION
  components DecompressionC as Compression;
#endif
  components RFReceiverC as Rf;
  Rf.AMControl -> ActiveMessageC;
  // Set up the buffer 
  Serial.InBuffer->FlashBuffer;
#ifdef NO_COMPRESSION
  Rf.OutBuffer->FlashBuffer;
#else
  Rf.OutBuffer->CompressionBuffer;
  Compression.InBuffer->CompressionBuffer;
  Compression.OutBuffer->FlashBuffer;
  
  // Set up the data layer
  Rf.AMSend -> AMSenderC;
  Rf.Packet -> ActiveMessageC.Packet;
  Rf.AMPacket -> ActiveMessageC.AMPacket;
  
  Rf.Leds -> LedsC.Leds;
#endif
#endif // --------------------------------------

  App.Boot->MainC;
  Serial.Boot->MainC;
  
  App.Leds->LedsC;
  App.GIO3->GIO.Port26; // 6-pin connector -> outer middle pin
  
  App.FlashWriter->Flash;
  App.FlashReader->Flash;
  
  App.Serial->Serial;
#ifndef NO_COMPRESSION
  App.Compression->Compression;
#endif
  App.Rf->Rf;

  Flash.BlockRead->ImageStorage;
  Flash.BlockWrite->ImageStorage;
  Flash.BufferLowLevel->FlashBuffer;
  Flash.Buffer->FlashBuffer;
}