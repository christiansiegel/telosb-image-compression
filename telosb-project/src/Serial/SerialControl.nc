interface SerialControl {
  /**
   * PC wants access flash.
   */
  event void flashAccessOk();

  /**
   * Mote entered flash access state.
   */
  command void flashAccessStart();

  /**
   * Mote left flash access state.
   */
  command void flashAccessEnd();

  /**
   * PC wants the mote to enter RF transmission state
   */
  event void rfTransmissionOk();

  /**
   * Mote entered RF transmission state
   */
  command void rfTransmissionStart();

  /**
   * Mote left RF transmission state.
   */
  command void rfTransmissionEnd();

#ifdef RECEIVER
  /**
   * Signals that the sending has ended.
   *
   * @param error
   *    <li>SUCCESS sending was successful
   */
  event void sendDone(error_t error);
#endif
}