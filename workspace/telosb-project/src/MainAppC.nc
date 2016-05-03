#include "StorageVolumes.h"

configuration MainAppC {
}
implementation {
	components MainC, BlinkC, LedsC;
	components new TimerMilliC() as Timer0;
	components FlashC;
	components new BlockStorageC(IMAGE);

    FlashC.BlockRead->BlockStorageC.BlockRead;
    FlashC.BlockWrite->BlockStorageC.BlockWrite;
	BlinkC.Boot->MainC.Boot;
	BlinkC.Timer0->Timer0;
	BlinkC.Leds->LedsC;
	BlinkC.Flash->FlashC;
}