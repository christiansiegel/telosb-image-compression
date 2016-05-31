/**
 * Read data from the flash.
 */
interface FlashReader {
  /**
   * Start reading.
   *
   * @return
   *    <li>EBUSY if already reading or writing
   *    <li>EINVAL if wired buffer has unexpected size
   *    <li>SUCCESS reader is successfully started
   */
  command error_t read();

  /**
   * Signals that the reading has ended.
   *
   * @param error
   *    <li>SUCCESS of all image byte were read
   */
  event void readDone(error_t error);
}