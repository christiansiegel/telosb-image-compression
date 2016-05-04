#ifndef DEF_H
#define DEF_H

/**
 * Compression algorithm to be used
 */
//#define FELICS     
#define TRUNCATE_1 
//#define TRUNCATE_2 
//#define TRUNCATE_4 

/**
 * Size of buffer which is consumed by Compression module.
 */
#define COMPRESS_IN_BUF_SIZE    1024

/**
 * Size of blocks that are compressed at once before
 * re-posting the compression task.
 */
#define COMPRESS_BLOCK_SIZE     256

/**
 * Size of circular buffer between Compression module
 * and Send module.
 */
#define SEND_IN_BUF_SIZE        1024

/**
 * Package payload size of the send package.
 * (114 is the maximum package payload for the telosb)
 */
#define PAYLOAD_SIZE            114

#endif /* DEF_H */
