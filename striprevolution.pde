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

#include "FastSPI_LED2.h"

//const uint8_t NUM_LEDS = 238;
const uint8_t NUM_LEDS = 5;
const uint8_t DATA_PIN = 6;
const EOrder  RGB_ORDER = GRB;

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

  void showColor( const CRGB &color ) { m_data.showColor(color); }
  void showColor( const CRGB &color, uint8_t brightness )
        { m_data.showColor(color, brightness); }
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

  enum Mode
  {
    IDLE,
    COMMAND,
    COLORS_HEAD,
    COLORS_READ,
    SINGLE_COLOR,
    COLORS_ALL,
    SET_BRIGHT,
    SET_RAINBOW
  };

  enum Command
  {
      COMMAND_NOP          = 0x0,
      COMMAND_COLOR        = 0x1,
      COMMAND_UNICOLOR     = 0x2,
      COMMAND_SINGLE_COLOR = 0x5,
      COMMAND_TEST         = 0x3,
      COMMAND_TESTRAW      = 0x4,
      COMMAND_DEBUG        = 0x6,
      COMMAND_BRIGHT       = 0x7,
      COMMAND_RAINBOW      = 0x8
  };
  
  CommandParser()  
  : m_bufsize( 256 )
  , m_mode(IDLE)
  , m_numberOfValuesToRead( 0 )
  , m_currentValueIndex( 0 )
  , m_magic( 0x42 )
  , m_debug( false )
  {   
    m_input_buffer = new char(m_bufsize);
    Serial.begin(9600);
  }
  
  ~CommandParser()
        {
          delete[] m_input_buffer;
          m_input_buffer = 0;
        }
  
  bool parse_input()
  {
    CRGB color;

    int avail = Serial.available();
    if (avail <=0)
    {return true;}
    
    memset( m_input_buffer, 0, m_bufsize );
    int rb = Serial.readBytes( m_input_buffer,
                               (m_bufsize > avail ? avail : m_bufsize ));
    if( rb > 0)
    {
      m_debug && Serial.print( "Read ");
      m_debug && Serial.print( rb );
      m_debug && Serial.println( " bytes");
    }
    for( int i=0; i<rb; ++i )
    {
      m_debug && Serial.print( "Processing byte ");
      m_debug && Serial.print( i);
      m_debug && Serial.print( " of ");
      m_debug && Serial.print( rb);
      m_debug && Serial.print( " (");
      m_debug && Serial.print( avail);
      m_debug && Serial.println( " total)");

      // check current byte
      uint8_t c = m_input_buffer[i];

      switch( m_mode )
      {
      case IDLE:
        if ( c == m_magic ) { m_mode = COMMAND; }
        else {       
          m_debug && Serial.println("ERROR: Wrong magic number");
        }
        break;
      
      case COMMAND:

        switch( c )
        {
        case COMMAND_NOP:
          m_debug && Serial.println("COMMAND_NOP");
          m_mode = IDLE;
          m_debug && Serial.println("OK");
          break;
        case COMMAND_COLOR:
          m_debug && Serial.println("COMMAND_COLOR");
          m_mode = COLORS_HEAD;
          break;
        case COMMAND_UNICOLOR:
          m_debug && Serial.println("COMMAND_UNICOLOR");
          m_numberOfValuesToRead = 3;
          m_currentValueIndex = 0;
          m_mode = COLORS_ALL;
          break;
        case COMMAND_TEST:
          m_debug && Serial.println("COMMAND_TEST");
          testPattern();
          m_mode = IDLE;
          m_debug && Serial.println("OK");
          break;
        case COMMAND_TESTRAW:
          m_debug && Serial.println("COMMAND_TESTRAW");
          testPatternRaw();
          m_mode = IDLE;
          m_debug && Serial.println("OK");
          break;
        case COMMAND_DEBUG:
          m_debug && Serial.println("COMMAND_DEBUG");
          m_debug = !m_debug;
          m_mode = IDLE;
          m_debug && Serial.println("OK");
          break;
        case COMMAND_SINGLE_COLOR:
          m_debug && Serial.println("COMMAND_SINGLE_COLOR");
          m_mode = SINGLE_COLOR;
          break;
        case COMMAND_BRIGHT:
          m_debug && Serial.println("COMMAND_BRIGHT");
          m_mode = SET_BRIGHT;
          break;
        case COMMAND_RAINBOW:
          m_debug && Serial.println("COMMAND_RAINBOW");
          m_buffer.rainbow();
          m_mode = IDLE;
          m_debug && Serial.println("SET_RAINBOW");
          break;
        default:
          m_mode = IDLE;
          m_debug && Serial.println("ERROR: Unknown command");
          break;
        }
        break;

      case SET_BRIGHT:
      {
        uint8_t  bright_val = m_input_buffer[i];
        m_buffer.setBrightness(bright_val);
        m_mode = IDLE;
      
        m_debug && Serial.print("SET_BRIGHT");
        m_debug && Serial.println( bright_val);
        //m_debug && Serial.println();
        break;
      }

      case SINGLE_COLOR:

        memcpy( &color, m_input_buffer + i, 3 );
        i = i + 2;
        m_buffer.showColor( color );
        m_mode = IDLE;

        m_debug && Serial.print(" SINGLE_COLOR ");
        m_debug && Serial.print( i );
        m_debug && Serial.print( " color ");
        m_debug && Serial.print( color[0] );
        m_debug && Serial.print(", ");
        m_debug && Serial.print( color[1] );
        m_debug && Serial.print(", ");
        m_debug && Serial.print( color[2] );
        m_debug && Serial.println( " " );

        break;

      case COLORS_HEAD:
        m_numberOfValuesToRead = c * 3;
        m_currentValueIndex = 0;
        m_mode = COLORS_READ;
        debugcounter = 0;
        break;

      case COLORS_READ:
      {
        uint8_t* colorValues      = reinterpret_cast< uint8_t* >(m_buffer.leds());
        uint8_t  valuesAvailable  = rb - i;
        uint8_t  valuesLeft       = m_numberOfValuesToRead - m_currentValueIndex;
        uint8_t  valuesToRead     = (valuesAvailable < valuesLeft) ? valuesAvailable : valuesLeft;

        m_debug && Serial.print( debugcounter++ );
        m_debug && Serial.print(" Read LED ");
        m_debug && Serial.print( valuesToRead );
        m_debug && Serial.print(" index ");
        m_debug && Serial.print( m_currentValueIndex );
        m_debug && Serial.print(" i ");
        m_debug && Serial.print( i );

        size_t copyNumber = static_cast< size_t >( valuesToRead );

        memcpy( colorValues + m_currentValueIndex, m_input_buffer + i, copyNumber );

        m_currentValueIndex  = m_currentValueIndex + valuesToRead;
        i                    = i + valuesToRead;


        m_debug && Serial.print(" AFTER ");
        m_debug && Serial.print( valuesToRead );
        m_debug && Serial.print( " numberofvalues ");
        m_debug && Serial.print( m_numberOfValuesToRead );
        m_debug && Serial.print(" index ");
        m_debug && Serial.print( m_currentValueIndex );
        m_debug && Serial.print(" i ");
        m_debug && Serial.println( i );


        if( m_currentValueIndex >= m_numberOfValuesToRead )
        {
          m_buffer.show();
          m_mode = IDLE;
          m_debug && Serial.println("OK");
        }
        break;
      }
      case COLORS_ALL:
      {
        uint8_t* data      = reinterpret_cast< uint8_t* >(m_buffer.leds());
        uint8_t  valuesAvailable  = rb - i;
        uint8_t  valuesLeft       = m_numberOfValuesToRead - m_currentValueIndex;
        uint8_t  valuesToRead     = (valuesAvailable < valuesLeft) ? valuesAvailable : valuesLeft;

        m_debug && Serial.print("Setting ");
        m_debug && Serial.print( valuesToRead );
        m_debug && Serial.print( "/" );
        m_debug && Serial.print( valuesLeft );
        m_debug && Serial.println(" color values");

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
          m_mode = IDLE;
          m_debug && Serial.println("OK");
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
    for( uint8_t i=0; i<NUM_LEDS; ++i)
    { // Red
      setRGB(buf+3*i, brightness, 0, 0);
    }
    m_buffer.show(); delay(500);
    for( uint8_t i=0; i<NUM_LEDS; ++i)
    { // Green
      setRGB(buf+3*i, 0, brightness, 0);
    }
    m_buffer.show(); delay(500);
    for( uint8_t i=0; i<NUM_LEDS; ++i)
    { // Blue
      setRGB(buf+3*i, 0, 0, brightness);
    }
    m_buffer.show(); delay(500);
    for( uint8_t i=0; i<NUM_LEDS; ++i)
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

  uint16_t debugcounter;
  Buffer m_buffer;
  uint8_t m_magic;
  bool m_debug;
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
