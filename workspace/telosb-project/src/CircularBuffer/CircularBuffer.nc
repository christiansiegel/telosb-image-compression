/**
 * Circular byte buffer.
 */
interface CircularBuffer {
  /**
   * Clear buffer.
   */
  command void clear();

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

  /**
   * Returns free space in number of bytes.
   *
   * @return Returns the free space in number of bytes.
   */
  command uint16_t free();

  /**
   * Returns number of available bytes.
   *
   * @return Returns the number of available bytes.
   */
  command uint16_t available();
}