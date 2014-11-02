#include "CommandParser.h"

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

// needed for free memory calculation
extern int* __brkval;

CommandParser::CommandParser()
: m_mode( IDLE )
, m_debug( false )
, m_numberOfValuesToRead( 0 )
, m_currentValueIndex( 0 )
, m_avail( 0 )
, m_readBytes( 0 )
, m_index( 0 )
{}

void CommandParser::init(nleds_t nleds)
{
  m_buffer = new LEDBuffer(nleds);
  Serial.begin(BAUDRATE);
}

CommandParser::~CommandParser()
{
  if( m_buffer) delete m_buffer;
}

#ifndef SAVEMEM
void CommandParser::log_msg_real( bool debug,
                                  const char * format_string, ... ) const
{
  if( !(m_debug && debug) ) return;
  va_list args;
  va_start (args, format_string);
  vsnprintf (m_log_buffer, LOG_BUFSIZE, format_string, args);
  Serial.println( m_log_buffer );
  va_end (args);
}
#endif

bool CommandParser::read_serial()
{
  if( m_index < m_readBytes)
      return true;
  m_avail = Serial.available();
  if( m_avail <= 0)
      return false;
  memset( m_input_buffer, 0, INPUT_BUFSIZE );
  m_index = 0;
  m_readBytes = Serial.readBytes(
      m_input_buffer, (INPUT_BUFSIZE > m_avail ? m_avail : INPUT_BUFSIZE ));
  return true;
}

void CommandParser::parse_input()
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
    else if(m_input_buffer[m_index] == char(0xff)) {
      // workaround for XBees
      ++m_index;
    }
    else {
      Serial.println( F("Wrong magic number"));
#ifdef SERIAL_DEBUG
      Serial.print("BEGIN ");
      while(m_index < m_readBytes)
      {
        Serial.print(char(m_input_buffer[m_index++]));
      }
      Serial.println(" END");
#else
      ++m_index;
#endif
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
      m_buffer->showColor( CRGB::Black );
      m_mode = IDLE;
      break;
    case COMMAND_BRIGHT:
      log_msg( true, "COMMAND_BRIGHT");
      m_mode = SET_BRIGHT;
      break;
    case COMMAND_RAINBOW:
      log_msg( true, "COMMAND_RAINBOW");
      m_buffer->rainbow();
      m_mode = IDLE;
      break;
    case COMMAND_STATE:
    {
      log_msg( true, "COMMAND_STATE");
      uint8_t* leds =  m_buffer->leds_raw();
      unsigned int n = m_buffer->size(); n*=3;
      for( unsigned int i=0; i < n; ++i)
          Serial.print((char) *(leds+i));
      Serial.flush();
      m_mode = IDLE;
      break;
    }
    case COMMAND_TEST:
      log_msg( true, "COMMAND_TEST");
      testPattern();
      m_mode = IDLE;
      break;
    case COMMAND_CONF:
      Serial.print(F("nleds: "));
      Serial.println(m_buffer->size());
      Serial.print(F("nleds_max: "));
      Serial.println(nleds_t(-1));
      Serial.println(F("speed:  "STR(BAUDRATE)));
      Serial.print( F("debug: "));
      Serial.println(m_debug);
      m_mode = IDLE;
      break;
    case COMMAND_DEBUG:
      log_msg( true, "COMMAND_DEBUG");
#ifndef SAVEMEM
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
      Serial.print("0");
      Serial.flush();
      m_mode = IDLE;
      break;
    case COMMAND_MEMFREE:
      log_msg( true, "COMMAND_MEMFREE");
      Serial.print(F("Free RAM: "));
      Serial.println(__brkval ? int(SP)-int(__brkval) :
                    int(SP)-int(__malloc_heap_start));
      m_mode = IDLE;
      break;
    default:
      Serial.println( F("Unknown command"));
      m_mode = IDLE;
      break;
    }
    break;

  case SET_BRIGHT:
  {
    uint8_t bright_val = get_value<uint8_t>();
    log_msg( true, "SET_BRIGHT %d", bright_val);
    m_buffer->setBrightness(bright_val);
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
    get_values( m_buffer->leds_raw(), m_numberOfValuesToRead);
    m_buffer->show();
    m_mode = IDLE;
    break;
  }
  
  case COLORS_ALL:
  {
    log_msg( true, "COLORS_ALL");
    uint8_t  color[3];
    uint8_t* data  = m_buffer->leds_raw();
    get_values( color, 3);
    for( unsigned int led_idx=0; led_idx < m_buffer->size(); ++led_idx)
    {
        *(data++) = *(color);
        *(data++) = *(color+1);
        *(data++) = *(color+2);
    }
    m_buffer->show();
    m_mode = IDLE;
    break;
  }
  
  case SET_SIZE:
  {
    nleds_t newsize = get_value<nleds_t>();
    if( newsize != m_buffer->size())
    {
      log_msg( true, "SET_SIZE %u", newsize);
      m_buffer->showColor( CRGB::Black );
      delete m_buffer;
      m_buffer = new LEDBuffer(newsize);
    }
    m_mode = IDLE;
    break;
  }
  
  default:
    Serial.print(F("Unknown mode "));
    Serial.println(m_mode);
    m_mode = IDLE;
    break;
  }
}

void CommandParser::testPattern( uint8_t brightness )
{
  m_buffer->showColor( CRGB::Red, brightness );
  delay(500);
  m_buffer->showColor( CRGB::Green, brightness );
  delay(500);
  m_buffer->showColor( CRGB::Blue, brightness );
  delay(500);
  m_buffer->showColor( CRGB::Magenta, brightness );
  delay(500);
  m_buffer->showColor( CRGB::Cyan, brightness );
  delay(500);
  m_buffer->showColor( CRGB::Yellow, brightness );
  delay(500);
  m_buffer->showColor( CRGB::Black );
  delay(500);
}
