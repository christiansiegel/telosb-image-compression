/**
 * Compression of data.
 */
interface Compression {
  /**
   * Starts compression process.
   *
   * @return
   *    <li>EBUSY if the compression is already running
   *    <li>SUCCESS if the compression has been started successfully
   */
  command error_t compress();

  /**
   * Signals the end of the compression.
   *
   * @param error   SUCCESS if the decompression was successful.
   */
  event void compressDone(error_t error);
}