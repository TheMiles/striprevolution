// -*- mode: c++ -*-
// Uncomment this line if you have any interrupts that are changing pins - this causes the library to be a little bit more cautious
// #define FAST_SPI_INTERRUPTS_WRITE_PINS 1

// Uncomment this line to force always using software, instead of hardware, SPI (why?)
// #define FORCE_SOFTWARE_SPI 1

// Uncomment this line if you want to talk to DMX controllers
// #define FASTSPI_USE_DMX_SIMPLE 1

// minicom -b 9600 -D /dev/ttyUSB0
// echo -en "\x42\x01\x01\x0F\x00\x00" > /dev/ttyUSB0
// echo -en "\x42\x01\x05\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF" > /dev/ttyUSB0
// echo -en "\x42\x01\x05\xF\xF\xF\xF\xF\xF\xF\xF\xF\xF\xF\xF\xF\xF\xF" > /dev/ttyUSB0
// echo -e "\x42\x01\x05\x0F\x00\x00" > /dev/ttyUSB0
  enum Mode
  {
    IDLE,
    COMMAND,
    COLORS_HEAD,
    COLORS_READ,
    SINGLE_COLOR,
    COLORS_ALL,
    SET_BRIGHT,
    SET_RAINBOW,
    SET_SIZE,
  };

#include "FastSPI_LED2.h"


//const uint8_t NUM_LEDS = 238;
const uint8_t  NUM_LEDS = 255;
const uint8_t  DATA_PIN = 6;
const EOrder   RGB_ORDER = GRB;
const uint16_t LOG_STRING_LENGTH = 1024;



class Buffer
{
public:
  Buffer(uint8_t numLeds = NUM_LEDS)
  : m_numLeds( numLeds )
  , m_leds( NULL )
  {
    m_leds = reinterpret_cast< CRGB* >(malloc( m_numLeds * sizeof( CRGB ) ));
    memset( m_leds, 0, m_numLeds * sizeof( CRGB ) );
    m_data.addLeds<WS2811, DATA_PIN, RGB_ORDER>(m_leds, m_numLeds);
    m_data.setBrightness(255);
    m_data.show();
  }

  virtual ~Buffer()
  {
    free( m_leds );
    m_leds = NULL;
  }

  CRGB* leds() { return m_leds; }
  CFastSPI_LED2* data() { return &(m_data); }
    
  uint8_t size() const { return m_numLeds; }

  void showColor( const CRGB &color ) 
  { 
    for( uint8_t i = 0; i < m_numLeds; ++i )
    {
      memcpy( m_leds + i, &color, sizeof( CRGB ) );
    }

    m_data.show();
  }

  void showColor( CRGB color, uint8_t brightness )
  {
    color.nscale8_video( brightness );
    showColor( color );
  }
  
  void show() { m_data.show(); }

  void setBrightness(uint8_t brightness )
        {
          m_data.show(brightness);
        }
  void rainbow()
        {
          fill_rainbow(leds(), size(), 0, uint8_t(255/size()) );
          m_data.show();
        }


private:
   uint8_t       m_numLeds;
  CRGB*         m_leds;
  CFastSPI_LED2 m_data;
};

class CommandParser
{
public:

  // enum Mode
  // {
  //   IDLE,
  //   COMMAND,
  //   COLORS_HEAD,
  //   COLORS_READ,
  //   SINGLE_COLOR,
  //   COLORS_ALL,
  //   SET_BRIGHT,
  //   SET_RAINBOW,
  //   SET_SIZE,
  // };

  enum Command
  {
      COMMAND_NOP          = 0x0,
      COMMAND_COLOR        = 0x1,
      COMMAND_UNICOLOR     = 0x2,
      COMMAND_SINGLE_COLOR = 0x3,
      COMMAND_BRIGHT       = 0x4,
      COMMAND_RAINBOW      = 0x5,
      COMMAND_TEST         = 0x61,
      COMMAND_TESTRAW      = 0x62,
      COMMAND_CONF         = 0x67,
      COMMAND_DEBUG        = 0x68,
      COMMAND_RESET        = 0x69,
      COMMAND_SETSIZE      = 0x70,
  };

  enum LogLevel
  {
    INFO,
    ERROR,
    CHATTY,
    DEBUG,
  };
  
  CommandParser()  
  : m_bufsize( 256 )
  , m_mode(IDLE)
  , m_numberOfValuesToRead( 0 )
  , m_currentValueIndex( 0 )
  , m_magic( 0x42 )
  , m_logLevel( DEBUG )
  {   
    m_input_buffer = new char(m_bufsize);
    Serial.begin(9600);

    testPattern(0x0f);
  }
  
  ~CommandParser()
        {
          delete[] m_input_buffer;
          m_input_buffer = 0;
        }

  void log_msg( LogLevel log_level, const char * format_string, ... )
  {
    // if the sent message has a higher log level than currently set, skip reporting this message
    if( log_level > m_logLevel  ) return;

    char buffer[LOG_STRING_LENGTH];
    va_list args;
    va_start (args, format_string);
    vsnprintf (buffer, LOG_STRING_LENGTH, format_string, args);
    Serial.println( buffer );
    va_end (args);
  }

  Mode mode( Mode new_mode )
  {
    m_mode = new_mode;
    log_msg( DEBUG, "New mode: %d", m_mode);
    return m_mode;
  }

  Mode mode() const
  {
    return m_mode;
  }
  
  void parse_input()
  {
    CRGB color;

    int avail = Serial.available();
    if( avail <= 0)
        return;
    memset( m_input_buffer, 0, m_bufsize );
    int rb = Serial.readBytes( m_input_buffer,
                               (m_bufsize > avail ? avail : m_bufsize ));
    if( rb > 0)
    {
      log_msg( DEBUG, "Read %d bytes", rb );
    }
    for( int i=0; i<rb; ++i )
    {
      log_msg( DEBUG, "Processing byte %d of %d (%d total)", i, rb, avail );

      // check current byte
      uint8_t c = m_input_buffer[i];

      switch( mode() )
      {
      case IDLE:
        if ( c == m_magic ) { mode( COMMAND ); }
        else {       
          log_msg( ERROR, "Wrong magic number");
        }
        break;
      
      case COMMAND:

        switch( c )
        {

        case COMMAND_NOP:
          log_msg( DEBUG, "COMMAND_NOP");
          mode( IDLE );
          break;

        case COMMAND_COLOR:
          log_msg( DEBUG, "COMMAND_COLOR");
          mode( COLORS_HEAD );
          break;

        case COMMAND_UNICOLOR:
          log_msg( DEBUG, "COMMAND_UNICOLOR");
          m_numberOfValuesToRead = 3;
          m_currentValueIndex = 0;
          mode( COLORS_ALL );
          break;

        case COMMAND_TEST:
          log_msg( DEBUG, "COMMAND_TEST");
          testPattern();
          mode( IDLE );
          break;

        case COMMAND_TESTRAW:
          log_msg( DEBUG, "COMMAND_TESTRAW");
          testPatternRaw();
          mode( IDLE );
          break;

        case COMMAND_DEBUG:
          log_msg( DEBUG, "COMMAND_DEBUG");
          m_logLevel = (m_logLevel != DEBUG) ? DEBUG : ERROR;
          mode( IDLE );
          break;

        case COMMAND_SINGLE_COLOR:
          log_msg( DEBUG, "COMMAND_SINGLE_COLOR");
          mode( SINGLE_COLOR );
          break;

        case COMMAND_BRIGHT:
          log_msg( DEBUG, "COMMAND_BRIGHT");
          mode( SET_BRIGHT );
          break;

        case COMMAND_RAINBOW:
          log_msg( DEBUG, "COMMAND_RAINBOW");
          m_buffer.rainbow();
          mode( IDLE );

        case COMMAND_RESET:
          log_msg( DEBUG, "COMMAND_RESET");
          m_buffer.showColor( CRGB::Black );
          mode( IDLE );
          break;

        case COMMAND_CONF:
          log_msg( DEBUG, "COMMAND_CONF");
          log_msg( INFO, "#NUMLEDS=%u", m_buffer.size() );
          mode( IDLE );
          break;

        case COMMAND_SETSIZE:
          log_msg( DEBUG, "COMMAND_SETSIZE");
          mode( SET_SIZE );
          break;

        default:
          log_msg( ERROR, "Unknown command");
          mode( IDLE );
          break;
        }
      break;

      case SET_BRIGHT:
      {
        uint8_t  bright_val = m_input_buffer[i];
        log_msg( DEBUG, "SET_BRIGHT %d", bright_val);
        m_buffer.setBrightness(bright_val);
        mode( IDLE );
        break;
      }

      case SET_SIZE:
      {
        log_msg( DEBUG, "SET_SIZE old %d size %d sizeof %d", (int) m_buffer.leds(), m_buffer.size(), sizeof( m_buffer.leds() ) );
        
        uint8_t new_size = m_input_buffer[i];
        m_buffer = Buffer( new_size );
        mode( IDLE );

        log_msg( DEBUG, "SET_SIZE new %d size %d sizeof %d", (int) m_buffer.leds(), m_buffer.size(), sizeof( m_buffer.leds() ) );

        log_msg( DEBUG, "SET_SIZE %d result %d", new_size, m_buffer.size() );
        break;
      }

      case SINGLE_COLOR:
      {
        memcpy( &color, m_input_buffer + i, 3 );
        i = i + 2;
        m_buffer.showColor( color );
        log_msg( DEBUG, "SINGLE_COLOR %d color %d, %d, %d ", i, color[0], color[1], color[2] );
        mode( IDLE );


        break;
      }

      case COLORS_HEAD:
      {
        m_numberOfValuesToRead = c * 3;
        m_currentValueIndex = 0;
        log_msg( DEBUG, "COLORS_HEAD numValuesToRead %d idx %d", m_numberOfValuesToRead, m_currentValueIndex );
        mode( COLORS_READ );
        break;
      }

      case COLORS_READ:
      {
        uint8_t* colorValues      = reinterpret_cast< uint8_t* >(m_buffer.leds());
        uint8_t  valuesAvailable  = rb - i;
        uint8_t  valuesLeft       = m_numberOfValuesToRead - m_currentValueIndex;
        uint8_t  valuesToRead     = (valuesAvailable < valuesLeft) ? valuesAvailable : valuesLeft;

        log_msg( DEBUG, "Read LED %d index %d i %d", valuesToRead, m_currentValueIndex, i );

        size_t copyNumber = static_cast< size_t >( valuesToRead );

        memcpy( colorValues + m_currentValueIndex, m_input_buffer + i, copyNumber );

        m_currentValueIndex  = m_currentValueIndex + valuesToRead;
        i                    = i + valuesToRead;


        log_msg( DEBUG, " AFTER %d index %d i %d", valuesToRead, m_currentValueIndex, i );

        if( m_currentValueIndex >= m_numberOfValuesToRead )
        {
          m_buffer.show();
          mode( IDLE );
        }
        break;
      }
      case COLORS_ALL:
      {
        uint8_t* data      = reinterpret_cast< uint8_t* >(m_buffer.leds());
        uint8_t  valuesAvailable  = rb - i;
        uint8_t  valuesLeft       = m_numberOfValuesToRead - m_currentValueIndex;
        uint8_t  valuesToRead     = (valuesAvailable < valuesLeft) ? valuesAvailable : valuesLeft;

        log_msg( DEBUG, "Setting %d/%d num leds %d", valuesToRead, valuesLeft, m_buffer.size() );

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
          mode( IDLE );
        }
        break;
      }
      }
    }
  }
  
  void testPattern( uint8_t brightness=255)
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

  void setRGB( uint8_t* data, uint8_t r, uint8_t g, uint8_t b)
        {
          *data     = r;
          *(data+1) = g;
          *(data+2) = b;
        }
  
  void testPatternRaw( uint8_t brightness=255)
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
  
private:
  const int m_bufsize;
  char* m_input_buffer;
  Mode m_mode;
  uint16_t m_numberOfValuesToRead;
  uint16_t m_currentValueIndex;

  Buffer m_buffer;
  uint8_t m_magic;
  LogLevel m_logLevel;
};

CommandParser *command_parser;

void setup() {
  // sanity check delay - allows reprogramming if accidently blowing power w/leds
  delay(2000); 
  command_parser = new CommandParser;
}

void loop() {
  command_parser->parse_input();
}
