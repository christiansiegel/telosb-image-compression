/**
 * Generic implementation of the CircularBuffer interface with
 * variable buffer size.
 * @param SIZE  buffer size
 */
generic module CircularBufferC(uint16_t SIZE) @safe() {
	provides interface CircularBuffer;
}
implementation {
	/**
	 * Internal byte array.
	 */
	uint8_t buf[SIZE];

	/**
	 * Pointer to first available byte
	 * (unless equal to @see end).
	 */
	uint16_t start = 0;

	/**
	 * Pointer to first invalid byte.
	 */
	uint16_t end = 0;

	command void CircularBuffer.clear() {
		start = 0;
		end = 0;
	}

	command error_t CircularBuffer.read(uint8_t * byte) {
		if(start == end) {
			return FAIL;
		}
		else {
			*byte = buf[start++];
			if(start == SIZE) 
				start = 0;
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
				block[i++] = buf[start++];
				if(start == SIZE) 
					start = 0;
			}
			while(--len > 0);
			return SUCCESS;
		}
	}

	command error_t CircularBuffer.write(uint8_t byte) {
		if(end + 1 == start || (end + 1 == SIZE && start == 0)) {
			return FAIL;
		}
		else {
			buf[end++] = byte;
			if(end == SIZE) 
				end = 0;
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
				buf[end++] = block[i++];
				if(end == SIZE) 
					end = 0;
			}
			while(--len > 0);
			return SUCCESS;
		}
	}

	command uint16_t CircularBuffer.available() {
		if(start <= end) 
			return end - start;
		else 
			return SIZE - start + end;
	}

	command uint16_t CircularBuffer.free() {
		if(start <= end) 
			return SIZE - end + start;
		else 
			return start + end;
	}
}