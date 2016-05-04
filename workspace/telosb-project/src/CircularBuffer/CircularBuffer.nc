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
	 * @param byte     byte to read into
	 * @return FAIL if buffer is empty | SUCCESS if byte was read.
	 */
	command error_t read(uint8_t * byte);
	
	/**
     * Read byte block from buffer.
     * @param block     byte array to read into
     * @param len       length of byte array
     * @return FAIL if not enough bytes available | SUCCESS if block was read.
     */
	command error_t read_block(uint8_t * block, uint16_t len);
	
	/**
     * Write single byte to buffer.
     * @param byte     byte to write
     * @return FAIL if buffer is full | SUCCESS if byte was written.
     */
	command error_t write(uint8_t byte);
	
	/**
     * Write byte block to buffer.
     * @param block     byte array to write to buffer
     * @param len       length of byte array
     * @return FAIL if not enough free space | SUCCESS if block was written.
     */
	command error_t write_block(uint8_t * block, uint16_t len);
	
	/**
	 * Returns free space in number of bytes.
	 * @return free space in number of bytes
	 */
	command uint16_t free();
	
	/**
     * Returns number of available bytes.
     * @return number of available bytes
     */
	command uint16_t available();
}