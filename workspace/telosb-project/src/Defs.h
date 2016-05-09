#ifndef DEFS_H
#define DEFS_H

#include "Config.h"

#ifdef PRINTF_DEBUG
#include "printf.h"
#define PRINTLN(fmt, ...) do { printf(fmt, ##__VA_ARGS__); printf("\n"); printfflush(); } while(0);
#endif

#define IMAGE_STORAGE   0
#define IMAGE_SIZE      65536

#endif /* DEFS_H */
