/**
 * Decompression of data.
 */
interface Decompression {
  /**
   * Starts decompression process.
   *
   * @return
   *    <li>EBUSY if the decompression is already running
   *    <li>SUCCESS if the decompression has been started successfully
   */
  command error_t compress();

  /**
   * Signals the end of the decompression.
   *
   * @return
   *    <li>SUCCESS if the decompression was successful.
   */
  event void compressDone(error_t error);
}