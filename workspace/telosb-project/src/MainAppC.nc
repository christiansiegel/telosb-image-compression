configuration MainAppC {
}
implementation {
	components MainC, BlinkC, LedsC;
	components new TimerMilliC() as Timer0;

	BlinkC.Boot->MainC.Boot;
	BlinkC.Timer0->Timer0;
	BlinkC.Leds->LedsC;
}