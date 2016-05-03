#include "Timer.h"

// flash write read example/test:


module BlinkC @safe() {
	uses interface Timer<TMilli> as Timer0;
	uses interface Leds;
	uses interface Boot;
	uses interface Flash;
}
implementation {
	uint8_t counter;
	uint8_t tmp;

	event void Boot.booted() {
		//call Timer0.startPeriodic(250);
		call Leds.set(1);
		call Flash.erase();
	}

	event void Timer0.fired() {
		counter++;
		call Leds.set(counter);
	}

	event void Flash.readDone(error_t result){
		// TODO Auto-generated method stub
		call Leds.set(tmp);
	}

	event void Flash.writeDone(error_t result){
		call Leds.set(2);
        tmp = 0;		
		call Flash.read(&tmp, 5, sizeof(tmp));
	}

	event void Flash.eraseDone(error_t result){
		tmp = 3;
		call Leds.set(4);
		call Flash.write(&tmp, 5, sizeof(tmp));
	}
}