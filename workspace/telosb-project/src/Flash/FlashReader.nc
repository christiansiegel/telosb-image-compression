/**
 * Read data from the flash.
 */
interface FlashReader {
  /**
   * Start reading.
   *
   * @returns
   *     TODO
   */
  command error_t read();

  /**
   * Signals that the reading has ended.
   *
   * @param error    TODO
   */
  event void readDone(error_t error);
}