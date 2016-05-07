/**
 * Generic implementation of the Flash interface to read and write block from
 * the flash.
 *
 * @param BLOCK_SIZE Size of the blocks.
 */
generic module FlashC(uint16_t BLOCK_SIZE) {
  uses {
    interface BlockRead;
    interface BlockWrite;
  }
  provides interface Flash;
}
implementation {
  command error_t Flash.erase() { return call BlockWrite.erase(); }

  event void BlockWrite.eraseDone(error_t error) {
    signal Flash.eraseDone(error);
  }

  command error_t Flash.writeBlock(uint8_t * block, uint16_t pos) {
    return call BlockWrite.write(pos * BLOCK_SIZE, block, BLOCK_SIZE);
  }

  event void BlockWrite.writeDone(storage_addr_t addr, void *buf,
                                  storage_len_t len, error_t error) {
    signal Flash.writeDone(buf, error);
  }

  command error_t Flash.sync() { return call BlockWrite.sync(); }

  event void BlockWrite.syncDone(error_t error) {
    signal Flash.syncDone(error);
  }

  command error_t Flash.readBlock(uint8_t * block, uint16_t pos) {
    error_t Status = call BlockRead.read(pos * BLOCK_SIZE, block, BLOCK_SIZE);
    return Status;
  }

  event void BlockRead.readDone(storage_addr_t addr, void *buf,
                                storage_len_t len, error_t error) {
    signal Flash.readDone(buf, error);
  }

  event void BlockRead.computeCrcDone(storage_addr_t addr, storage_len_t len,
                                      uint16_t crc, error_t error) {}
}