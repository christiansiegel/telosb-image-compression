interface Decompression {
  command InitDecompression(storage_addr_t out_flash_addr);
  command DecompressNextChunk(uint8_t* out_chunk);
  event void decompressChunkDone(uint8_t* out_chunk);
}
