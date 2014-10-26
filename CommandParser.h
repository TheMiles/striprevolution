#include "Buffer.h"

#define STR_HELPER(x) #x
#define STR(x) STR_HELPER(x)

#define LOG_BUFSIZE   128
#define INPUT_BUFSIZE 128
#define BAUDRATE      115200

#define MAGIC 0x42

#define DATA_PIN  6
#define RGB_ORDER GRB                        \

#include "Commands.h"

class CommandParser
{
  typedef uint16_t nleds_t;
  typedef Buffer<nleds_t,DATA_PIN,RGB_ORDER> LEDBuffer;
  
  enum Mode
  {
    IDLE,
    COMMAND,
    COLORS_HEAD,
    COLORS_READ,
    COLORS_ALL,
    SET_BRIGHT,
    SET_SIZE,
    MODE_MAX
  };

public:
  CommandParser();
  ~CommandParser();
  
  void init(nleds_t nleds);
  
  void parse_input();
  
private:
  // logging takes loads of SRAM, so we wrap it with a macro and make it
  // optional
#ifndef SAVEMEM
  void log_msg_real( bool debug, const char * format_string, ... ) const;
  mutable char m_log_buffer[LOG_BUFSIZE];
#define log_msg(...) log_msg_real(__VA_ARGS__)
#else
#define log_msg(...)
#endif

  bool read_serial();
  
  void testPattern( uint8_t brightness=255);

  template<typename T> T get_value();

  void get_values( uint8_t* dest, uint16_t len);
  
  Mode m_mode;
  bool m_debug;
  char m_input_buffer[INPUT_BUFSIZE];

  unsigned int m_numberOfValuesToRead;
  unsigned int m_currentValueIndex;
  
  int m_avail;
  int m_readBytes;
  int m_index;
  
  LEDBuffer* m_buffer;
};

template<typename T>
T CommandParser::get_value()
{
  T ret = 0;
  m_currentValueIndex = 0;

  while( m_currentValueIndex < sizeof(T))
  {
    while( !read_serial());
    uint8_t offset = (sizeof(T) - m_currentValueIndex-1)*8;
    ret |= uint8_t(m_input_buffer[m_index++]) << offset;
    ++m_currentValueIndex;
  }
  return ret;
}

template<>
inline
uint8_t CommandParser::get_value<uint8_t>()
{
  while( !read_serial());
  return uint8_t(m_input_buffer[m_index++]);
}

inline
void CommandParser::get_values( uint8_t* dest, uint16_t len)
{
  m_currentValueIndex = 0;
  while( m_currentValueIndex < len)
  {
    while( !read_serial());
    *(dest++) = m_input_buffer[m_index++];
    ++m_currentValueIndex;
  }
}

