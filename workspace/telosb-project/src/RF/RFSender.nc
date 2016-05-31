interface RFSender 
{
   /**
    * Start sending.
    *
    * @returns
    *     TODO
    */
	command error_t send();
	
    /**
    * Send last package even if remaining input is smaller than the payload size.
    */
	command void flush();
	
	/**
 	* Signals the the sending is done.
	*
	* @param error     TODO
	*/
    event void sendDone(error_t error);
	
}