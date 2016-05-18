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
  command error_t decompress();

  /**
   * Signals the end of the decompression.
   *
   * @param error   SUCCESS if the decompression was successful.
   */
  event void decompressDone(error_t error);
}