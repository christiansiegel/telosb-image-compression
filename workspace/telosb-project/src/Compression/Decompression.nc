interface Decompression {
  command void InitDecompression(storage_addr_t out_flash_addr);
  command void DecompressNextChunk(uint8_t* out_chunk);
  event void decompressChunkDone(uint8_t* out_chunk);
}
