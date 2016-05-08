interface CircularBufferWrite {
  /**
   * Clear buffer.
   */
  command void clear();

  /**
   * Returns free space in number of bytes.
   *
   * @return Returns the free space in number of bytes.
   */
  command uint16_t free();

  /**
   * Write single byte to buffer.
   *
   * @param byte     byte to write
   *
   * @return
   *    <li>FAIL if buffer is full
   *    <li>SUCCESS  if byte was written
   */
  command error_t write(uint8_t byte);

  /**
   * Write byte block to buffer.
   *
   * @param block     The byte array to write to buffer.
   * @param len       The length of byte array.
   *
   * @return
   *    <li>FAIL if not enough free space
   *    <li>SUCCESS if block was written
   */
  command error_t writeBlock(uint8_t * block, uint16_t len);
}