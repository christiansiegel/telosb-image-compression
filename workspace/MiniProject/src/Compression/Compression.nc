interface Compression {
  command InitCompression(storage_addr_t in_flash_addr);
  command CompressNextChunk(uint8_t* out_chunk);
  event void compressChunkDone(uint8_t* out_chunk);
}
