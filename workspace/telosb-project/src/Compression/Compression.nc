interface Compression {
  command void InitCompression(storage_addr_t in_flash_addr);
  command void CompressNextChunk(uint8_t* out_chunk);
  event void compressChunkDone(uint8_t* out_chunk);
}
