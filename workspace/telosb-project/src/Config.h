#ifndef CONFIG_H
#define CONFIG_H

/**
 * Use Felics lossless compression.
 */
#define FELICS

/**
 * Use lossy compression that truncates
 * the LSB of every image byte.
 */
//#define TRUNCATE_1

/**
 * Use lossy compression that truncates
 * the two LSBs of every image byte.
 */
//#define TRUNCATE_2

/**
 * Use lossy compression that truncates
 * the four LSBs of every image byte.
 */
//#define TRUNCATE_4

/**
 * Size of buffer which is consumed by Compression module.
 */
#define COMPRESS_IN_BUF_SIZE 1024

/**
 * Size of blocks that are compressed at once before
 * re-posting the compression task.
 */
#define COMPRESS_BLOCK_SIZE 256

/**
 * Size of circular buffer between Compression module
 * and Send module.
 */
#define SEND_IN_BUF_SIZE 1024

/**
 * Package payload size of the send package.
 * (114 byte is the maximum package payload for the telosb)
 */
#define PAYLOAD_SIZE 114

#endif /* CONFIG_H */