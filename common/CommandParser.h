#ifndef COMMANDPARSER_H
#define COMMANDPARSER_H

#include <stdint.h>
#include <string.h>

#if defined(HAVE_AVR)
#include <util/delay.h>
#include <WString.h>
// needed for free memory calculation
extern int* __brkval;
#elif defined(HAVE_TEENSY3)
#include <util/delay.h>
#include <WProgram.h>
#else
#define F(x) (x)
#include <cstdarg>
#include <cstdio>
#include <unistd.h>
#define _delay_ms(x) usleep(1000*(x))
#endif

#define STR_HELPER(x) #x
#define STR(x) STR_HELPER(x)

#ifndef BAUDRATE
#define BAUDRATE      115200
#endif

static const uint8_t  LOG_BUFSIZE   = 128;
static const uint8_t  INPUT_BUFSIZE = 128;

static const uint8_t  MAGIC = 0x42;

static const uint8_t  VERSION_MAJ =   0;
static const uint16_t VERSION_MIN =   1;

#include "Commands.h"

template<typename nleds_t,typename buffer_t,typename serial_t>
class CommandParser
{
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
  CommandParser(serial_t& serial);
  ~CommandParser();
  
  void init(nleds_t nleds);
  
  void parse_input();

  void testPattern();

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
  
  serial_t& m_serial;
  buffer_t  m_buffer;
};

// that's the way a reset should be done but the device will just keep on 
// resetting (maybe disabling the watchdog in .init3 does not work for some
// reason) - jumping to 0x0 instead (which is not as clean as registers are not
// getting reinitialised).
#if 0
#include <avr/wdt.h>

void wdt_init (void) __attribute__ ((naked, used, section (".init3")));
void wdt_init (void)
{
  MCUSR = 0;
  wdt_disable();
  return;
}

void reset_func()
{
  wdt_enable(WDTO_15MS);
  while(1);
}
#else
void (*reset_func)() = 0;
#endif

template<typename nleds_t,typename buffer_t,typename serial_t>
CommandParser<nleds_t,buffer_t,serial_t>::CommandParser(serial_t& serial)
: m_mode( IDLE )
#ifdef SERIAL_DEBUG
, m_debug( true)
#else
, m_debug( false )
#endif
, m_numberOfValuesToRead( 0 )
, m_currentValueIndex( 0 )
, m_avail( 0 )
, m_readBytes( 0 )
, m_index( 0 )
, m_serial(serial)
{}

template<typename nleds_t,typename buffer_t,typename serial_t>
void CommandParser<nleds_t,buffer_t,serial_t>::init(nleds_t nleds)
{
  m_buffer.init(nleds);
  m_serial.begin(BAUDRATE);
}

template<typename nleds_t,typename buffer_t,typename serial_t>
CommandParser<nleds_t,buffer_t,serial_t>::~CommandParser()
{
  m_buffer.free();
}

#ifndef SAVEMEM
#ifdef LINUX
template<typename nleds_t,typename buffer_t,typename serial_t>
void CommandParser<nleds_t,buffer_t,serial_t>::log_msg_real(
    bool debug, const char * format_string, ... ) const
{
  if( !(m_debug && debug) ) return;
  va_list args;
  va_start (args, format_string);
  printf(format_string, args);
  printf("\n");
  va_end (args);
}
#else
template<typename nleds_t,typename buffer_t,typename serial_t>
void CommandParser<nleds_t,buffer_t,serial_t>::log_msg_real(
    bool debug, const char * format_string, ... ) const
{
  if( !(m_debug && debug) ) return;
  va_list args;
  va_start (args, format_string);
  vsnprintf (m_log_buffer, LOG_BUFSIZE, format_string, args);
  m_serial.println( m_log_buffer );
  va_end (args);
}
#endif
#endif

template<typename nleds_t,typename buffer_t,typename serial_t>
bool CommandParser<nleds_t,buffer_t,serial_t>::read_serial()
{
  if( m_index < m_readBytes)
      return true;
  m_avail = m_serial.available();
  if( m_avail <= 0)
      return false;
  memset( m_input_buffer, 0, INPUT_BUFSIZE );
  m_index = 0;
  m_readBytes = m_serial.readBytes(
      m_input_buffer, (INPUT_BUFSIZE > m_avail ? m_avail : INPUT_BUFSIZE ));
  return true;
}

template<typename nleds_t,typename buffer_t,typename serial_t>
void CommandParser<nleds_t,buffer_t,serial_t>::parse_input()
{
  if( !read_serial())
      return;
  
  switch( m_mode )
  {
  case IDLE:
    if ( m_input_buffer[m_index] == MAGIC ) {
      m_mode = COMMAND;
      ++m_index;
    }
    // else if(m_input_buffer[m_index] == char(0xff)) {
    //   // workaround for XBees
    //   ++m_index;
    // }
    else {
      m_serial.print( F("Wrong magic number"));
      m_serial.println( char(m_input_buffer[m_index]));
#ifdef LINUX
      printf("Wrong magic number: 0x%02x\n",char(m_input_buffer[m_index]));
#endif
      ++m_index;
    }
    break;
    
  case COMMAND:
    switch( m_input_buffer[m_index++] )
    {
    case COMMAND_NOP:
      log_msg( true, "COMMAND_NOP");
      m_mode = IDLE;
      break;
    case COMMAND_COLOR:
      log_msg( true, "COMMAND_COLOR");
      m_mode = COLORS_HEAD;
      break;
    case COMMAND_UNICOLOR:
      log_msg( true, "COMMAND_UNICOLOR");
      m_numberOfValuesToRead = 3;
      m_currentValueIndex = 0;
      m_mode = COLORS_ALL;
      break;
    case COMMAND_BLANK:
      log_msg( true, "COMMAND_BLANK");
      m_buffer.clear();
      m_mode = IDLE;
      break;
    case COMMAND_BRIGHT:
      log_msg( true, "COMMAND_BRIGHT");
      m_mode = SET_BRIGHT;
      break;
    case COMMAND_RAINBOW:
      log_msg( true, "COMMAND_RAINBOW");
      m_buffer.rainbow();
      m_mode = IDLE;
      break;
    case COMMAND_STATE:
    {
      log_msg( true, "COMMAND_STATE");
      uint8_t* leds =  m_buffer.leds_raw();
      unsigned int n = m_buffer.size(); n*=3;
      for( unsigned int i=0; i < n; ++i)
          m_serial.print((char) *(leds+i));
      m_serial.flush();
      m_mode = IDLE;
      break;
    }
    case COMMAND_TEST:
      log_msg( true, "COMMAND_TEST");
      testPattern();
      m_mode = IDLE;
      break;
    case COMMAND_CONF:
      m_serial.print(F("nleds: "));
      m_serial.println(m_buffer.size());
      m_serial.print(F("nleds_max: "));
      m_serial.println(nleds_t(-1));
      m_serial.println(F("speed:  " STR(BAUDRATE)));
      m_serial.print( F("debug: "));
      m_serial.println(m_debug);
      m_mode = IDLE;
      break;
    case COMMAND_DEBUG:
      log_msg( true, "COMMAND_DEBUG");
#ifndef SERIAL_DEBUG
      m_debug = !m_debug;
#endif
      m_mode = IDLE;
      break;
    case COMMAND_RESET:
      log_msg( true, "COMMAND_RESET");
      reset_func();
      m_mode = IDLE;
      break;
    case COMMAND_SETSIZE:
      log_msg( true, "COMMAND_SETSIZE");
      m_currentValueIndex = 0;
      m_mode = SET_SIZE;
      break;
    case COMMAND_PING:
      m_serial.print("0");
      m_serial.flush();
      m_mode = IDLE;
      break;
    case COMMAND_MEMFREE:
      log_msg( true, "COMMAND_MEMFREE");
#ifdef HAVE_AVR
      m_serial.print(F("Free RAM: "));
      m_serial.println(__brkval ? int(SP)-int(__brkval) :
                    int(SP)-int(__malloc_heap_start));
#else
      m_serial.print(F("Not supported"));
#endif
      m_mode = IDLE;
      break;
    case COMMAND_VERSION:
      log_msg( true, "COMMAND_VERSION" );
      m_serial.print( F("Version: ") );
      m_serial.print( VERSION_MAJ );
      m_serial.print( F(".") );
      m_serial.println( VERSION_MIN );
      m_mode = IDLE;
      break;
    default:
      m_serial.println( F("Unknown command"));
      m_mode = IDLE;
      break;
    }
    break;

  case SET_BRIGHT:
  {
    uint8_t bright_val = get_value<uint8_t>();
    log_msg( true, "SET_BRIGHT %d", bright_val);
    m_buffer.setBrightness(bright_val);
    m_mode = IDLE;
    break;
  }
  
  case COLORS_HEAD:
  {
    log_msg( true, "COLORS_HEAD");
    m_numberOfValuesToRead = get_value<nleds_t>();
    m_numberOfValuesToRead *= 3;
    log_msg( true, "COLORS_HEAD numValuesToRead %d",
             m_numberOfValuesToRead);
    m_mode = COLORS_READ;
    break;
  }
  
  case COLORS_READ:
  {
    log_msg( true, "COLORS_READ");
    get_values( m_buffer.leds_raw(), m_numberOfValuesToRead);
    m_buffer.show();
    m_mode = IDLE;
    break;
  }
  
  case COLORS_ALL:
  {
    log_msg( true, "COLORS_ALL");
    uint8_t  color[3];
    uint8_t* data  = m_buffer.leds_raw();
    get_values( color, 3);
    for( unsigned int led_idx=0; led_idx < m_buffer.size(); ++led_idx)
    {
        *(data++) = *(color);
        *(data++) = *(color+1);
        *(data++) = *(color+2);
    }
    m_buffer.show();
    m_mode = IDLE;
    break;
  }
  
  case SET_SIZE:
  {
    nleds_t newsize = get_value<nleds_t>();
    if( newsize != m_buffer.size())
    {
      log_msg( true, "SET_SIZE %u", newsize);
      m_buffer.clear();
      m_buffer.init(newsize);
    }
    m_mode = IDLE;
    break;
  }
  
  default:
    m_serial.print(F("Unknown mode "));
    m_serial.println(m_mode);
    m_mode = IDLE;
    break;
  }
}

template<typename nleds_t,typename buffer_t,typename serial_t>
void CommandParser<nleds_t,buffer_t,serial_t>::testPattern()
{
  m_buffer.showColor( 0xFF, 0x00, 0x00);
  _delay_ms(500);
  m_buffer.showColor( 0x00, 0xFF, 0x00);
  _delay_ms(500);
  m_buffer.showColor( 0x00, 0x00, 0xFF);
  _delay_ms(500);
  m_buffer.showColor( 0xFF, 0xFF, 0x00);
  _delay_ms(500);
  m_buffer.showColor( 0x00, 0xFF, 0xFF);
  _delay_ms(500);
  m_buffer.showColor( 0xFF, 0x00, 0xFF);
  _delay_ms(500);
  m_buffer.clear();
  _delay_ms(500);
}

template<typename nleds_t,typename buffer_t,typename serial_t>
template<typename T>
T CommandParser<nleds_t,buffer_t,serial_t>::get_value()
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

// template<typename nleds_t,typename buffer_t,typename serial_t>
// template<>
// uint8_t CommandParser<nleds_t,buffer_t,serial_t>::get_value<uint8_t>()
// {
//   return uint8_t(m_input_buffer[m_index++]);
// }

template<typename nleds_t, typename buffer_t,typename serial_t>
inline
void CommandParser<nleds_t,buffer_t,serial_t>::get_values( uint8_t* dest, uint16_t len)
{
  m_currentValueIndex = 0;
  while( m_currentValueIndex < len)
  {
    while( !read_serial());
    *(dest++) = m_input_buffer[m_index++];
    ++m_currentValueIndex;
  }
}

#endif
