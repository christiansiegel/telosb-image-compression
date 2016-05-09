/**
 * Generic implementation of an intermediate layer between a circular buffer and
 * the flash to read/write a huge amount of data (e.g. an image). It
 * reads/writes half the size of the circular buffer to the flash while the
 * other half of the buffer stays available for the consumer/producer on the
 * other end of the buffer.
 * Assumptions were made that the date to be read/written is a multiple of the
 * size of the used circular buffer.
 *
 * @param DATA_SIZE     Size of the data to be read/written.
 */
generic module FlashC(uint32_t DATA_SIZE) {
  uses {
    interface CircularBufferWrite as Buffer;
    interface CircularBufferLowLevel as BufferLowLevel;
    interface BlockRead;
    interface BlockWrite;
  }
  provides {
    interface FlashReader;
    interface FlashWriter;
  }
}
implementation {
  uint8_t *_buffer;
  uint16_t *_bufferStart;
  uint16_t *_bufferEnd;
  uint16_t _bufferSize;
  uint16_t _bufferMiddle;

  bool _running;
  uint32_t _byteCounter;

  task void readTask() {
    static int posted;

    if (*_bufferEnd == 0 &&
        (*_bufferStart > _bufferMiddle || *_bufferStart == 0)) {
      // first half of buffer is empty -> fill with flash data
      posted = call BlockRead.read(_byteCounter,  // flash pos
                                   _buffer,       // buffer pos
                                   _bufferMiddle  // size
                                   ) == SUCCESS;

    } else if (*_bufferEnd == _bufferMiddle && *_bufferStart <= _bufferMiddle &&
               *_bufferStart != 0) {
      // second half of buffer is empty -> fill with flash data
      posted = call BlockRead.read(_byteCounter,                // flash pos
                                   _buffer + _bufferMiddle,     // buffer pos
                                   _bufferSize - _bufferMiddle  // size
                                   ) == SUCCESS;
    } else {
    	posted = FALSE;
    }
    if (!posted) post readTask();
  }

  task void writeTask() {
    static int posted;

    if (*_bufferStart == 0 && *_bufferEnd >= _bufferMiddle) {
      // first half of buffer is available -> write data to flash
      posted = call BlockWrite.write(_byteCounter,  // flash pos
                                     _buffer,       // buffer pos
                                     _bufferMiddle  // size
                                     ) == SUCCESS;
    } else if (*_bufferStart == _bufferMiddle && *_bufferEnd < _bufferMiddle) {
      // second half of buffer is available -> write data to flash
      posted = call BlockWrite.write(_byteCounter,                // flash pos
                                     _buffer + _bufferMiddle,     // buffer pos
                                     _bufferSize - _bufferMiddle  // size
                                     ) == SUCCESS;
    } else {
        posted = FALSE;
    }
    if (!posted) post writeTask();
  }

  event void BlockRead.readDone(storage_addr_t addr, void *buf,
                                storage_len_t len, error_t error) {
    // update process variables
    _byteCounter += len;
    *_bufferEnd = (buf == _buffer) ? _bufferMiddle : 0;

    if (_byteCounter >= DATA_SIZE) {
      // all data read
      _running = FALSE;
      signal FlashReader.readDone(SUCCESS);
    } else {
      // not done yet: re-post read task
      post readTask();
    }
  }

  event void BlockRead.computeCrcDone(storage_addr_t addr, storage_len_t len,
                                      uint16_t crc, error_t error) {}

  event void BlockWrite.eraseDone(error_t error) {
    if (error != SUCCESS) signal FlashWriter.writeDone(error);
    post writeTask();
  }

  event void BlockWrite.writeDone(storage_addr_t addr, void *buf,
                                  storage_len_t len, error_t error) {
    // update process variables
    _byteCounter += len;
    *_bufferStart = (buf == _buffer) ? _bufferMiddle : 0;

    if (_byteCounter >= DATA_SIZE) {
      // all data written
      error = call BlockWrite.sync();
      if (error != SUCCESS) signal FlashWriter.writeDone(error);
    } else {
      // not done yet: re-post write task
      post writeTask();
    }
  }

  event void BlockWrite.syncDone(error_t error) {
    _running = FALSE;
    signal FlashWriter.writeDone(error);
  }
  
  /**
   * Init state variables for read/write process.
   */
  void initBuffer() {
    _byteCounter = 0;
    call BufferLowLevel.get(&_buffer, &_bufferStart, &_bufferEnd, &_bufferSize);
    _bufferMiddle = _bufferSize;
    if (_bufferMiddle % 2 != 0) _bufferMiddle--;
    _bufferMiddle /= 2;
  }

  command error_t FlashReader.read() {
    if (_running) {
      return EBUSY;
    } else {
      initBuffer();
      if (DATA_SIZE % _bufferSize != 0) return EINVAL;
      call Buffer.clear();
      _running = TRUE;
      post readTask();
      return SUCCESS;
    }
  }

  command error_t FlashWriter.write() {
    if (_running) {
      return EBUSY;
    } else {
      initBuffer();
      if (DATA_SIZE % _bufferSize != 0) return EINVAL;
      _running = TRUE;
      return call BlockWrite.erase();
    }
  }
}