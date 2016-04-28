
interface Flash
{
	command error_t write(storage_addr_t pos, uint8_t *data, storage_len_t len);
	event void writeDone(error_t result);

	command error_t read(storage_addr_t pos, uint8_t *data, storage_len_t len);
	event void readDone(error_t result);
}
