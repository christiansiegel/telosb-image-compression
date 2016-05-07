/**
 * Process a set of input buffers.
 */
interface ProcessInput {
  /**
   * Starts input process.
   *
   * You have to provide an initial input via <code>newInput(uint8_t)</code>
   * after calling this command.
   *
   * @return 
   *    <li>EBUSY if the process is already running
   *    <li>SUCCESS if the process has been started successfully
   */
  command error_t start();

  /**
   * Signals the end of the input process.
   */
  event void done();

  /**
   * Provide new input data.
   *
   * @param buf  The input buffer with new data.
   *
   * @return 
   *    <li>ECANCEL if the process is not running
   *    <li>EFAIL if currently no new input is required
   *    <li>SUCCESS if the input has been provided successfully
   */
  command error_t newInput(uint8_t * buf);

  /**
   * Signals that the data provided previously with
   * <code>newInput(uint8_t)</code> has been consumed by the process. New data
   * has to be provided via <code>newInput(uint8_t)</code> in  order to
   * continue the process.
   *
   * @param buf  The consumed input buffer.
   */
  event void consumedInput(uint8_t * buf);
}