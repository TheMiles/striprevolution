#include "CommandParser.h"

const char* CommandParser::ModeText[MODE_MAX] =
{
    "IDLE",
    "COMMAND",
    "COLORS_HEAD",
    "COLORS_READ",
    "SINGLE_COLOR",
    "COLORS_ALL",
    "SET_BRIGHT",
    "SET_SIZE",
};
              
CommandParser::CommandParser()
: m_mode( IDLE )
, m_numberOfValuesToRead( 0 )
, m_currentValueIndex( 0 )
, m_logLevel( DEBUG )
{   
  Serial.begin(9600);
  testPattern(0x0f);
}

void CommandParser::log_msg( CommandParser::LogLevel log_level,
                             const char * format_string, ... ) const
{
  if( log_level > m_logLevel  ) return;
  
  char m_log_buffer[LOG_BUFSIZE];
  memset( m_log_buffer, 0, LOG_BUFSIZE);
  va_list args;
  va_start (args, format_string);
  vsnprintf (m_log_buffer, LOG_BUFSIZE, format_string, args);
  Serial.println( m_log_buffer );
  va_end (args);
}

void CommandParser::setMode( Mode new_mode )
{
  log_msg( DEBUG, "setMode: %s", ModeText[new_mode]);
  m_mode = new_mode;
}

CommandParser::Mode CommandParser::mode() const
{
  return m_mode;
}

void CommandParser::parse_input()
{
  CRGB color;
  char m_input_buffer[INPUT_BUFSIZE];
  int avail = Serial.available();
  if( avail <= 0)
      return;
  memset( m_input_buffer, 0, INPUT_BUFSIZE );
  int rb = Serial.readBytes( m_input_buffer,
                             (INPUT_BUFSIZE > avail ? avail : INPUT_BUFSIZE ));
  if( rb > 0)
  {
    log_msg( DEBUG, "Read %d bytes", rb );
  }
  for( int i=0; i<rb; ++i )
  {
    log_msg( DEBUG, "Processing byte %d of %d (%d total)", i+1, rb, avail );

    // check current byte
    uint8_t c = m_input_buffer[i];

    switch( mode() )
    {
    case IDLE:
      if ( c == MAGIC ) {
        setMode( COMMAND );
      }
      else {       
        log_msg( ERROR, "Wrong magic number");
      }
      break;
    
    case COMMAND:
      switch( c )
      {
      case COMMAND_NOP:
        log_msg( DEBUG, "COMMAND_NOP");
        setMode( IDLE );
        break;
      case COMMAND_COLOR:
        log_msg( DEBUG, "COMMAND_COLOR");
        setMode( COLORS_HEAD );
        break;
      case COMMAND_UNICOLOR:
        log_msg( DEBUG, "COMMAND_UNICOLOR");
        m_numberOfValuesToRead = 3;
        m_currentValueIndex = 0;
        setMode( COLORS_ALL );
        break;
      case COMMAND_SINGLE_COLOR:
        log_msg( DEBUG, "COMMAND_SINGLE_COLOR");
        setMode( SINGLE_COLOR );
        break;
      case COMMAND_BRIGHT:
        log_msg( DEBUG, "COMMAND_BRIGHT");
        setMode( SET_BRIGHT );
        break;
      case COMMAND_RAINBOW:
        log_msg( DEBUG, "COMMAND_RAINBOW");
        m_buffer.rainbow();
        setMode( IDLE );
        break;
      case COMMAND_TEST:
        log_msg( DEBUG, "COMMAND_TEST");
        testPattern();
        setMode( IDLE );
        break;
      case COMMAND_TESTRAW:
        log_msg( DEBUG, "COMMAND_TESTRAW");
        testPatternRaw();
        setMode( IDLE );
        break;
      case COMMAND_CONF:
        log_msg( DEBUG, "COMMAND_CONF");
        log_msg( INFO, "#NUMLEDS=%u", m_buffer.size() );
        setMode( IDLE );
        break;
      case COMMAND_DEBUG:
        log_msg( DEBUG, "COMMAND_DEBUG");
        m_logLevel = (m_logLevel != DEBUG) ? DEBUG : ERROR;
        setMode( IDLE );
        break;
      case COMMAND_RESET:
        log_msg( DEBUG, "COMMAND_RESET");
        m_buffer.showColor( CRGB::Black );
        setMode( IDLE );
        break;
      case COMMAND_SETSIZE:
        log_msg( DEBUG, "COMMAND_SETSIZE");
        setMode( SET_SIZE );
        break;
      default:
        log_msg( ERROR, "Unknown command");
        setMode( IDLE );
        break;
      }
      break;

    case SET_BRIGHT:
    {
      uint8_t  bright_val = m_input_buffer[i];
      log_msg( DEBUG, "SET_BRIGHT %d", bright_val);
      m_buffer.setBrightness(bright_val);
      setMode( IDLE );
      break;
    }

    case SET_SIZE:
    {
      log_msg( DEBUG, "SET_SIZE old %d size %d sizeof %d",
               (int) m_buffer.leds(), m_buffer.size(), sizeof( m_buffer.leds() ) );
      
      uint8_t new_size = m_input_buffer[i];
      m_buffer = Buffer( new_size );
      setMode( IDLE );

      log_msg( DEBUG, "SET_SIZE new %d size %d sizeof %d",
               (int) m_buffer.leds(), m_buffer.size(), sizeof( m_buffer.leds() ) );

      log_msg( DEBUG, "SET_SIZE %d result %d", new_size, m_buffer.size() );
      break;
    }

    case SINGLE_COLOR:
    {
      memcpy( &color, m_input_buffer + i, 3 );
      i += 2;
      m_buffer.showColor( color );
      log_msg( DEBUG, "SINGLE_COLOR %d color %d, %d, %d ",
               i, color[0], color[1], color[2] );
      setMode( IDLE );
      break;
    }

    case COLORS_HEAD:
    {
      m_numberOfValuesToRead = c * 3;
      m_currentValueIndex = 0;
      log_msg( DEBUG, "COLORS_HEAD numValuesToRead %d idx %d",
               m_numberOfValuesToRead, m_currentValueIndex );
      setMode( COLORS_READ );
      break;
    }

    case COLORS_READ:
    {
      uint8_t* colorValues      = reinterpret_cast< uint8_t* >(m_buffer.leds());
      uint8_t  valuesAvailable  = rb - i;
      uint8_t  valuesLeft       = m_numberOfValuesToRead - m_currentValueIndex;
      uint8_t  valuesToRead     =
          (valuesAvailable < valuesLeft) ? valuesAvailable : valuesLeft;

      log_msg( DEBUG, "Read LED %d index %d i %d",
               valuesToRead, m_currentValueIndex, i );

      size_t copyNumber = static_cast< size_t >( valuesToRead );

      memcpy( colorValues + m_currentValueIndex, m_input_buffer + i, copyNumber );

      m_currentValueIndex  = m_currentValueIndex + valuesToRead;
      i                    = i + valuesToRead;


      log_msg( DEBUG, " AFTER %d index %d i %d",
               valuesToRead, m_currentValueIndex, i );

      if( m_currentValueIndex >= m_numberOfValuesToRead )
      {
        m_buffer.show();
        setMode( IDLE );
      }
      break;
    }
    
    case COLORS_ALL:
    {
      uint8_t* data      = reinterpret_cast< uint8_t* >(m_buffer.leds());
      uint8_t  valuesAvailable  = rb - i;
      uint8_t  valuesLeft       = m_numberOfValuesToRead - m_currentValueIndex;
      uint8_t  valuesToRead     =
          (valuesAvailable < valuesLeft) ? valuesAvailable : valuesLeft;

      log_msg( DEBUG, "Setting %d/%d num leds %d",
               valuesToRead, valuesLeft, m_buffer.size() );

      for( int pos=0; pos<valuesToRead; ++pos)
      {
        for( int led_idx=0; led_idx < m_buffer.size(); ++led_idx)
        {
          *(data+m_currentValueIndex+pos+led_idx*3) =
              *(m_input_buffer+i+pos);
        }
        ++m_currentValueIndex;
        ++i;
      }

      if( m_currentValueIndex >= m_numberOfValuesToRead )
      {
        m_buffer.show();
        setMode( IDLE );
      }
      break;
    }
    
    default:
      log_msg( ERROR, "Unknown mode %d", m_mode);
      setMode( IDLE );
      break;
    }
  }
}

void CommandParser::testPattern( uint8_t brightness )
{
  m_buffer.showColor( CRGB::Red, brightness );
  delay(500);
  m_buffer.showColor( CRGB::Green, brightness );
  delay(500);
  m_buffer.showColor( CRGB::Blue, brightness );
  delay(500);
  m_buffer.showColor( CRGB::Magenta, brightness );
  delay(500);
  m_buffer.showColor( CRGB::Cyan, brightness );
  delay(500);
  m_buffer.showColor( CRGB::Yellow, brightness );
  delay(500);
  m_buffer.showColor( CRGB::Black );
  delay(500);
}

void CommandParser::setRGB( uint8_t* data, uint8_t r, uint8_t g, uint8_t b)
{
  *data     = r;
  *(data+1) = g;
  *(data+2) = b;
}

void CommandParser::testPatternRaw( uint8_t brightness )
{
  uint8_t* buf = reinterpret_cast< uint8_t* >(
      m_buffer.leds());
  for( uint8_t i=0; i<m_buffer.size(); ++i)
  { // Red
    setRGB(buf+3*i, brightness, 0, 0);
  }
  m_buffer.show(); delay(500);
  for( uint8_t i=0; i<m_buffer.size(); ++i)
  { // Green
    setRGB(buf+3*i, 0, brightness, 0);
  }
  m_buffer.show(); delay(500);
  for( uint8_t i=0; i<m_buffer.size(); ++i)
  { // Blue
    setRGB(buf+3*i, 0, 0, brightness);
  }
  m_buffer.show(); delay(500);
  for( uint8_t i=0; i<m_buffer.size(); ++i)
  { // Black
    setRGB(buf+3*i, 0, 0, 0);
  }
  m_buffer.show(); delay(500);
}

