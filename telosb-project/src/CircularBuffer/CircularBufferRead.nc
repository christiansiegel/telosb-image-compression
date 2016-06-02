interface CircularBufferRead {
  /**
   * Returns number of available bytes.
   *
   * @return Returns the number of available bytes.
   */
  command uint16_t available();

  /**
   * Read single byte from buffer.
   *
   * @param byte     The byte to read into.
   *
   * @return
   *    <li>FAIL if buffer is empty
   *    <li>SUCCESS if byte was read
   */
  command error_t read(uint8_t * byte);

  /**
   * Read byte block from buffer.
   *
   * @param block     The byte array to read into.
   * @param len       The length of byte array.
   *
   * @return
   *    <li>FAIL if not enough bytes available
   *    <li>SUCCESS if block was read
   */
  command error_t readBlock(uint8_t * block, uint16_t len);
}