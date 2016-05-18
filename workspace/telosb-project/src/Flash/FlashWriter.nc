/**
 * Write data to the flash.
 */
interface FlashWriter {
  /**
   * Start writing.
   *
   * @returns
   *     TODO
   */
  command error_t write();

  /**
   * Signals the the writing has ended.
   *
   * @param error     TODO
   */
  event void writeDone(error_t error);
}