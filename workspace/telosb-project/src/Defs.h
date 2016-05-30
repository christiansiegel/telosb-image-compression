#ifndef DEFS_H
#define DEFS_H

#include "Config.h"

#if !(defined(FELICS) ^ defined(TRUNCATE_1) ^ defined(TRUNCATE_2) ^ \
      defined(TRUNCATE_4) ^ defined(NO_COMPRESSION))
#error "You have to specify exactly one compression algorithm to use!"
#endif

#if !(defined(SENDER) ^ defined(RECEIVER))
#error "You have to define either SENDER or RECEIVER!"
#endif

#ifdef PRINTF_DEBUG
#include "printf.h"
#define PRINTLN(fmt, ...)       \
  do {                          \
    printf(fmt, ##__VA_ARGS__); \
    printf("\n");               \
    printfflush();              \
  } while (0);
// java net.tinyos.tools.PrintfClient -comm serial@/dev/ttyUSB0:telosb
#else
#define PRINTLN(fmt, ...)
#endif

void PRINT_DUMP(uint8_t *buf, uint8_t len) {
#ifdef PRINTF_DEBUG
	static uint8_t i;
	PRINTLN("DUMP START ---");
	for(i=0; i < len; ++i) {
		printf("0x%x ", buf[i]);
	}
	PRINTLN("\nDUMP END ---");
#endif
}

#define IMAGE_STORAGE 0
#define IMAGE_SIZE 65536

enum States {
  /**
   * Waiting for new commands from the control PC.
   */
  IDLE = 1,
  /**
   * PC accesses flash.
   */
  FLASH_ACCESS = 2,
  /**
   * Motes2mote transmission.
   */
  RF_TRANSMISSION = 4
};
typedef enum States state;

#ifdef FELICS

enum {
  /**
   * Parameter K of Golomb-Rice codes.
   */
  K = 2,
  /**
   * Bit flag for pixel values that are in the range of their two neighbors.
   */
  IN_RANGE = 0,
  /**
   * Bit flag for pixel values that are out of the range of their two
   * neighbors.
   */
  OUT_OF_RANGE = 1,
  /**
   * Bit flag for pixel values that are below the range of their two
   * neighbors.
   */
  BELOW_RANGE = 0,
  /**
   * Bit flag for pixel values that are above the range of their two
   * neighbors.
   */
  ABOVE_RANGE = 1
};

#endif

/**
 * Radio message structure. 
 */
typedef nx_struct reliable_msg_t {
	nx_uint8_t data[RF_PAYLOAD_SIZE];
} reliable_msg_t;
/**
 * Ack message structure. 
 */
typedef nx_struct ack_msg_t {
	} ack_msg_t; 

#endif /* DEFS_H */