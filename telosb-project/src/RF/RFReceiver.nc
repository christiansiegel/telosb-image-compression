interface RFReceiver {
  /**
   * Start receiving.
   *
   * @returns
   *     TODO
   */
  command error_t receive();

  /**
   * Signals the the receiving is done.
   *
   * @param error     TODO
   */
  event void receiveDone(error_t error);
}