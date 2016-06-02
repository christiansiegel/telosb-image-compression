/**
 * Write data to the flash.
 */
interface FlashWriter {
  /**
   * Start writing.
   *
   * @return
   *    <li>EBUSY if already reading or writing
   *    <li>EINVAL if wired buffer has unexpected size
   *    <li>SUCCESS reader is successfully started
   */
  command error_t write();

  /**
   * Signals the the writing has ended.
   *
   * @param error
   *    <li>EBUSY if flash sync failed
   *    <li>SUCCESS all image byte were read
   */
  event void writeDone(error_t error);
}