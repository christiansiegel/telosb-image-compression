
interface Flash
{
	command error_t write(uint8_t *data, uint16_t pos, uint16_t len);
	event void writeDone(error_t result);

	command error_t read(uint8_t *data, uint16_t pos, uint16_t len);
	event void readDone(error_t result);
}
