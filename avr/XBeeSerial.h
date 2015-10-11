#ifndef XBEESERIAL_H
#define XBEESERIAL_H

#include <XBee.h>

#define PAYLOAD_LENGTH 1

class XBeeSerial
{
public:
  XBeeSerial();
  
  void begin( int baudrate );
  void end();
  
  void setAddress( uint32_t sh, uint32_t sl );
  uint32_t getAddressH();
  uint32_t getAddressL();
  
  size_t print(const __FlashStringHelper *);
  size_t print(const char*);
  size_t print(char);
  size_t print(unsigned char, int = DEC);
  size_t print(int, int = DEC);
  size_t print(unsigned int, int = DEC);
  size_t print(long, int = DEC);
  size_t print(unsigned long, int = DEC);
  size_t print(double, int = 2);
  
  size_t println(const __FlashStringHelper *);
  size_t println(const char*);
  size_t println(char);
  size_t println(unsigned char, int = DEC);
  size_t println(int, int = DEC);
  size_t println(unsigned int, int = DEC);
  size_t println(long, int = DEC);
  size_t println(unsigned long, int = DEC);
  size_t println(double, int = 2);        
  size_t println(void);
  void flush();
  
  int available();
  int readBytes( char * output_buffer, int num_bytes_to_read );

private: 
  uint8_t             m_payload[PAYLOAD_LENGTH];
  XBee                m_xbee;
  XBeeAddress64       m_addr64;
  ZBTxRequest         m_zbTx;
  ZBTxStatusResponse  m_txStatus;
  ZBRxResponse        m_rxResponse;
};

#endif
