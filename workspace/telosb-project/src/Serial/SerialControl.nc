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
  event void imageTransmissionOk();

  /**
   * Mote entered RF transmission state
   */
  command void rfTransmissionStart();

  /**
   * Mote left RF transmission state.
   */
  command void rfTransmissionEnd();
}