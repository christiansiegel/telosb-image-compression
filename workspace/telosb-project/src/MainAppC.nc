#include "StorageVolumes.h"
#include "config.h"

configuration MainAppC {
}
implementation {
	components MainC, LedsC;
	components CompressionTestC;
	components FlashC;
	components new BlockStorageC(0);
	components CompressionC;
	components new CircularBufferC(SEND_IN_BUF_SIZE) as SendBuffer;

    FlashC.BlockRead->BlockStorageC.BlockRead;
    FlashC.BlockWrite->BlockStorageC.BlockWrite;
	CompressionTestC.Boot->MainC.Boot;
	CompressionTestC.Leds->LedsC.Leds;
	CompressionTestC.Flash->FlashC.Flash;
	CompressionTestC.Compression->CompressionC;
	CompressionTestC.SendBuffer->SendBuffer;
	CompressionC.OutBuffer->SendBuffer;
}
