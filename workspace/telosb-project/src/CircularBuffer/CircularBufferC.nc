/**
 * Generic implementation of a circular buffer.
 *
 * @param SIZE  The buffer size.
 */
generic module CircularBufferC(uint16_t SIZE) {
  provides {
    interface CircularBufferRead;
    interface CircularBufferWrite;
    interface CircularBufferLowLevel;
  }
}
implementation {
  /**
   * Internal byte array.
   */
  uint8_t _buf[SIZE];

  /**
   * Pointer to first available byte
   * (unless equal to <code>end</code>).
   */
  uint16_t _start = 0;

  /**
   * Pointer to first invalid byte.
   */
  uint16_t _end = 0;

  command void CircularBufferWrite.clear() {
    _start = 0;
    _end = 0;
  }

  command uint16_t CircularBufferRead.available() {
    if (_start <= _end)
      return _end - _start;
    else
      return SIZE - _start + _end;
  }

  command error_t CircularBufferRead.read(uint8_t * byte) {
    if (_start == _end) {
      return FAIL;
    } else {
      *byte = _buf[_start++];
      if (_start == SIZE) _start = 0;
      return SUCCESS;
    }
  }

  command error_t CircularBufferRead.readBlock(uint8_t * block, uint16_t len) {
    uint16_t i;
    if (call CircularBufferRead.available() < len) {
      return FAIL;
    } else {
      for (i = 0; i < len; i++) {
        block[i] = _buf[_start++];
        if (_start == SIZE) _start = 0;
      }
      return SUCCESS;
    }
  }

  command uint16_t CircularBufferWrite.free() {
    return SIZE - call CircularBufferRead.available() - 1;
  }

  command error_t CircularBufferWrite.write(uint8_t byte) {
    if (_end + 1 == _start || (_end + 1 == SIZE && _start == 0)) {
      return FAIL;
    } else {
      _buf[_end++] = byte;
      if (_end == SIZE) _end = 0;
      return SUCCESS;
    }
  }

  command error_t CircularBufferWrite.writeBlock(uint8_t * block,
                                                 uint16_t len) {
    uint16_t i;
    if (call CircularBufferWrite.free() < len) {
      return FAIL;
    } else {
      for (i = 0; i < len; i++) {
        _buf[_end++] = block[i];
        if (_end == SIZE) _end = 0;
      }
      return SUCCESS;
    }
  }

  command void CircularBufferLowLevel.get(uint8_t * *buffer, uint16_t * *start,
                                          uint16_t * *end, uint16_t * size) {
    *buffer = _buf;
    *start = &_start;
    *end = &_end;
    *size = SIZE;
  }
}