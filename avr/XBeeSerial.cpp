#include "XBeeSerial.h"

#if !defined (SERIALDEVICE)
#if defined(HAVE_TEENSY3)
#define SERIALDEVICE Serial2
#else
#define SERIALDEVICE Serial
#endif
#endif

XBeeSerial::XBeeSerial()
: m_xbee( XBee() )
{}

void XBeeSerial::begin( int baudrate )
{
	SERIALDEVICE.begin( baudrate );
	m_xbee.begin( SERIALDEVICE );

	memset( m_payload, 0, PAYLOAD_LENGTH );
	m_zbTx.setPayload( m_payload );
	m_zbTx.setPayloadLength( PAYLOAD_LENGTH );

	setAddress(0,0);
}

void XBeeSerial::end()
{
	SERIALDEVICE.end();
	memset( m_payload, 0, PAYLOAD_LENGTH );
}

void XBeeSerial::setAddress( uint32_t sh, uint32_t sl )
{
	m_addr64.setMsb( sh );
	m_addr64.setLsb( sl );
	m_zbTx.setAddress64( m_addr64 );
}   

uint32_t XBeeSerial::getAddressH()
{
	return m_addr64.getMsb();
}

uint32_t XBeeSerial::getAddressL()
{
	return m_addr64.getLsb();
}

size_t XBeeSerial::print(const __FlashStringHelper *f ) { 
	return print( (char*) f ); 
}

size_t XBeeSerial::print(const char *cstr ) {
	size_t count = 0;
	while( *cstr != 0 ) {
		count += print( *cstr++ );
	}
	return count;
}

size_t XBeeSerial::print(char c){

	size_t sentBytes = 0;

	m_payload[0] = c;

	m_xbee.send(m_zbTx);

	if (m_xbee.readPacket(500)) {
		if (m_xbee.getResponse().getApiId() == ZB_TX_STATUS_RESPONSE) {
			m_xbee.getResponse().getZBTxStatusResponse(m_txStatus);

			if (m_txStatus.getDeliveryStatus() == SUCCESS) {
				sentBytes = 1;
			} 
		}
	}

	return sentBytes;
}

size_t XBeeSerial::print(unsigned char value, int base){
	char buf[4];
	utoa( value, buf, base );
	return print( buf );
}

size_t XBeeSerial::print(int value, int base ){
	char buf[18];
	itoa( value, buf, base );
	return print( buf );
}

size_t XBeeSerial::print(unsigned int value, int base){
	char buf[17];
	utoa( value, buf, base );
	return print( buf );
}

size_t XBeeSerial::print(long value, int base ){
	char buf[34];
	ltoa( value, buf, base );
	return print( buf );
}

size_t XBeeSerial::print(unsigned long value, int base ){
	char buf[33];
	ultoa( value, buf, base );
	return print( buf );
}

size_t XBeeSerial::print(double value, int digits)
{
	char buf[40];
	memset( buf, 0, 40 );
	dtostrf(value, digits + 2, digits, buf);
	return print( buf );
}

size_t XBeeSerial::println(const __FlashStringHelper * f)
{
	size_t count = 0;
	count =  print (f);
	count += print ( '\n' );
	return count;
}

size_t XBeeSerial::println(const char* cstr)
{
	size_t count = 0;
	count =  print (cstr);
	count += print ( '\n' );
	return count;
}

size_t XBeeSerial::println(char c)
{
	size_t count = 0;
	count =  print (c);
	count += print ( '\n' );
	return count;
}

size_t XBeeSerial::println(unsigned char value, int base)
{
	size_t count = 0;
	count =  print (value,base);
	count += print ( '\n' );
	return count;
}

size_t XBeeSerial::println(int value, int base)
{
	size_t count = 0;
	count =  print (value,base);
	count += print ( '\n' );
	return count;
}

size_t XBeeSerial::println(unsigned int value, int base)
{
	size_t count = 0;
	count =  print (value,base);
	count += print ( '\n' );
	return count;
}

size_t XBeeSerial::println(long value, int base)
{
	size_t count = 0;
	count =  print (value,base);
	count += print ( '\n' );
	return count;
}

size_t XBeeSerial::println(unsigned long value, int base)
{
	size_t count = 0;
	count =  print (value,base);
	count += print ( '\n' );
	return count;
}

size_t XBeeSerial::println(double value, int digits)
{
	size_t count = 0;
	count =  print (value,digits);
	count += print ( '\n' );
	return count;
}

size_t XBeeSerial::println(void)
{
	return print ( '\n' );
}


void XBeeSerial::flush()
{}

int XBeeSerial::available()
{
	int availableBytes = 0;

	m_xbee.readPacket();
	if (m_xbee.getResponse().isAvailable()) {
		if (m_xbee.getResponse().getApiId() == ZB_RX_RESPONSE) {
			m_xbee.getResponse().getZBRxResponse(m_rxResponse);

			availableBytes = m_rxResponse.getDataLength();
		}
	}

	return availableBytes;
}

int XBeeSerial::readBytes( char * output_buffer, int num_bytes_to_read )
{    
	int actualNumBytesToRead = 0;

	m_xbee.readPacket();

	if (m_xbee.getResponse().isAvailable()) {
		if (m_xbee.getResponse().getApiId() == ZB_RX_RESPONSE) {
			m_xbee.getResponse().getZBRxResponse(m_rxResponse);

			actualNumBytesToRead = m_rxResponse.getDataLength();
			if( actualNumBytesToRead > num_bytes_to_read ) {
				actualNumBytesToRead = num_bytes_to_read;
			}

			memcpy( output_buffer, m_rxResponse.getData(), actualNumBytesToRead );

		} else if (m_xbee.getResponse().isError()) {
			// error happened
		}
	}

	return actualNumBytesToRead;
}
