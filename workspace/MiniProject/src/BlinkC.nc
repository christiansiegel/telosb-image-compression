#include "Timer.h"

module BlinkC @safe() {
	uses interface Timer<TMilli> as Timer0;
	uses interface Leds;
	uses interface Boot;
}
implementation {
	uint8_t counter;

	event void Boot.booted() {
		call Timer0.startPeriodic(250);
	}

	event void Timer0.fired() {
		counter++;
		call Leds.set(counter);
	}
}