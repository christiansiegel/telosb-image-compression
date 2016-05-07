/**
 * Read and write blocks from the flash.
 */
interface Flash {
  /**
   * Initiate an erase operation. On SUCCESS, the <code>eraseDone</code> event
   * will signal completion of the operation.
   *
   * @return
   *   <li>SUCCESS if the request was accepted,
   *   <li>EBUSY if a request is already being processed.
   */
  command error_t erase();

  /**
   * Signals the completion of an erase operation.
   *
   * @param error SUCCESS if the operation was successful, FAIL if it failed
   */
  event void eraseDone(error_t error);

  /**
   * Initiate a write operation. On SUCCESS, the <code>writeDone</code> event
   * will signal completion of the operation.
   * <p>
   * Between two erases, no byte may be written more than once.
   *
   * @param block The block to write.
   * @param pos The block position in the flash.
   *
   * @return
   *   <li>SUCCESS if the request was accepted,
   *   <li>EINVAL if the parameters are invalid
   *   <li>EBUSY if a request is already being processed.
   */
  command error_t writeBlock(uint8_t * block, uint16_t pos);

  /**
   * Signals the completion of a write operation. However, data is not
   * guaranteed to survive a power-cycle unless a sync operation has been
   * completed.
   *
   * @param block The written block.
   * @param error SUCCESS if the operation was successful, FAIL if it failed
   */
  event void writeDone(uint8_t * block, error_t error);

  /**
   * Initiate a sync operation to finalize writes to the volume. A sync
   * operation must be issued to ensure that data is stored in non-volatile
   * storage. On SUCCES, the <code>syncDone</code> event will signal completion
   * of the operation.
   *
   * @return
   *   <li>SUCCESS if the request was accepted,
   *   <li>EBUSY if a request is already being processed.
   */
  command error_t sync();

  /**
   * Signals the completion of a sync operation. All written data is flushed to
   * non-volatile storage after this event.
   *
   * @param error SUCCESS if the operation was successful, FAIL if it failed
   */
  event void syncDone(error_t error);

  /**
   * Initiate a read operation. On SUCCESS, the <code>readDone</code> event
   * will signal completion of the operation.
   *
   * @param block The block to read.
   * @param pos The block position in the flash.
   *
   * @return
   *   <li>SUCCESS if the request was accepted,
   *   <li>EINVAL if the parameters are invalid
   *   <li>EBUSY if a request is already being processed.
   */
  command error_t readBlock(uint8_t * block, uint16_t pos);

  /**
   * Signals the completion of a read operation.
   *
   * @param block The read block.
   * @param error SUCCESS if the operation was successful, FAIL if it failed
   */
  event void readDone(uint8_t * block, error_t error);
}