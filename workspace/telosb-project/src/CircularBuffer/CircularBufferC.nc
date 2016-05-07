/**
 * Generic implementation of the CircularBuffer interface with
 * variable buffer size.
 * 
 * @param SIZE  The buffer size.
 */
generic module CircularBufferC(uint16_t SIZE) {
	provides interface CircularBuffer;
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

	command void CircularBuffer.clear() {
		_start = 0;
		_end = 0;
	}

	command error_t CircularBuffer.read(uint8_t * byte) {
		if(_start == _end) {
			return FAIL;
		}
		else {
			*byte = _buf[_start++];
			if(_start == SIZE) 
				_start = 0;
			return SUCCESS;
		}
	}

	command error_t CircularBuffer.read_block(uint8_t * block, uint16_t len) {
		uint16_t i;
		if(call CircularBuffer.available() < len) {
			return FAIL;
		}
		else {
			i = 0;
			do {
				block[i++] = _buf[_start++];
				if(_start == SIZE) 
					_start = 0;
			}
			while(--len > 0);
			return SUCCESS;
		}
	}

	command error_t CircularBuffer.write(uint8_t byte) {
		if(_end + 1 == _start || (_end + 1 == SIZE && _start == 0)) {
			return FAIL;
		}
		else {
			_buf[_end++] = byte;
			if(_end == SIZE) 
				_end = 0;
			return SUCCESS;
		}
	}

	command error_t CircularBuffer.write_block(uint8_t * block, uint16_t len) {
		uint16_t i;
		if(call CircularBuffer.free() < len) {
			return FAIL;
		}
		else {
			i = 0;
			do {
				_buf[_end++] = block[i++];
				if(_end == SIZE) 
					_end = 0;
			}
			while(--len > 0);
			return SUCCESS;
		}
	}

	command uint16_t CircularBuffer.available() {
		if(_start <= _end) 
			return _end - _start;
		else 
			return SIZE - _start + _end;
	}

	command uint16_t CircularBuffer.free() {
		if(_start <= _end) 
			return SIZE - _end + _start;
		else 
			return _start + _end;
	}
}