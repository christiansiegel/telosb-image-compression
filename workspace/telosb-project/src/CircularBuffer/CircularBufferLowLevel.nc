interface CircularBufferLowLevel {
  /**
   * Get direct access to the internal buffer array for fast low level access.
   * BE CAREFUL!!!
   *
   * @param buffer   Pointer to the first buffer array element.
   * @param start    Pointer to the position of the first valid byte.
   * @param end      Pointer to the position of the first invalid byte.
   * @param size     Size of the buffer.
   */
  command void get(uint8_t * *buffer, uint16_t * *start, uint16_t * *end,
                   uint16_t * size);
}