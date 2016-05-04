/**
 * Process a set of input buffers.
 */
interface ProcessInput {
	/**
	 * Starts input process.
	 * You have to provide an initial input via @see new_input
	 * after calling this command.
	 * @return EBUSY   if the process is already running
	 *         SUCCESS if the process has been started successfully
	 */
	command error_t start();
	
	/**
	 * Signals the end of the input process.
	 */
	event void done();

	/**
	 * Provide new input data.
	 * @param buf  input buffer with new data
	 * @return ECANCEL     if the process is not running
	 *         EFAIL       if currently no new input is required 
	 *         SUCCESS     if the input has been provided successfully
	 */
	command error_t new_input(uint8_t * buf);

	/**
	 * Signals that the data provided previously with
	 * @see new_input has been consumed by the process.
	 * New data has to be provided via @see new_input in 
	 * order to continue the process.
	 * @param buf  consumed input buffer
	 */
	event void consumed_input(uint8_t * buf);
}