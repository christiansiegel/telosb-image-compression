module FlashC
{
	uses {
		interface BlockRead;
		interface BlockWrite;
	}
	provides {
		interface Flash;
	}
}
implementation 
{
	command error_t Flash.erase() {
        return call BlockWrite.erase();
    }
    
	event void BlockWrite.eraseDone(error_t error) {
		signal Flash.eraseDone(error);
    }
	
	command error_t Flash.write(uint8_t * data, uint16_t pos, uint16_t len) {
		error_t Status = call BlockWrite.write(pos * len, data, len);
		return Status;
	}

	command error_t Flash.read(uint8_t * data, uint16_t pos, uint16_t len) {
        error_t Status = call BlockRead.read(pos * len, data, len);
        return Status;
    }

	event void BlockWrite.writeDone(storage_addr_t addr, void *buf, storage_len_t len, error_t error) {
        call BlockWrite.sync();
    }

	event void BlockWrite.syncDone(error_t error) {
		signal Flash.writeDone(error);
	}

	event void BlockRead.readDone(storage_addr_t addr, void *buf, storage_len_t len, error_t error) {
        signal Flash.readDone(error);
    }

	event void BlockRead.computeCrcDone(storage_addr_t addr, storage_len_t len, uint16_t crc, error_t error) {
	}
}