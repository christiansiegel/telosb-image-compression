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
#define PRINTLN(fmt, ...) do { printf(fmt, ##__VA_ARGS__); printf("\n"); printfflush(); } while(0);
// java net.tinyos.tools.PrintfClient -comm serial@/dev/ttyUSB0:telosb
#endif

#define IMAGE_STORAGE   0
#define IMAGE_SIZE      65536

#endif /* DEFS_H */
