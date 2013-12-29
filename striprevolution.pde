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
//
// Toggle debug output:
// echo -en "\x42\x4" > /dev/ttyUSB0

#include "FastSPI_LED2.h"

//const uint8_t NUM_LEDS = 238;
const uint8_t NUM_LEDS = 5;
const uint8_t DATA_PIN = 6;
const EOrder  RGB_ORDER = GRB;

const int Input_Buffer_Length = 64;

const uint8_t MAGIC_NUMBER    = 0x42;
const uint8_t COMMAND_NOP     = 0x0;
const uint8_t COMMAND_COLOR   = 0x1;
const uint8_t COMMAND_TEST    = 0x2;
const uint8_t COMMAND_TESTRAW = 0x3;
const uint8_t COMMAND_DEBUG   = 0x4;
const uint8_t COMMAND_SINGLE_COLOR   = 0x5;

class Buffer
{
public:
  Buffer(uint8_t numLeds = NUM_LEDS)
  : m_numLeds( numLeds )
  , m_leds( NULL )
  {
    m_leds = reinterpret_cast< CRGB* >(malloc( m_numLeds * sizeof( CRGB ) ));
    memset( m_leds, 0, m_numLeds * sizeof( CRGB ) );

    m_data.setBrightness(255);
    m_data.addLeds<WS2811, DATA_PIN, RGB_ORDER>(m_leds, m_numLeds);
  }

  virtual ~Buffer()
  {
    free( m_leds );
    m_leds = NULL;
  }

  CRGB* leds() { return m_leds; }
  uint8_t size() { return m_numLeds; }

  void showColor( const CRGB &color ) { m_data.showColor(color); }
  void showColor( const CRGB &color, uint8_t brightness )
        { m_data.showColor(color, brightness); }
  void show() { m_data.show(); }


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
  };

  CommandParser()  
  : m_mode(IDLE)
  , m_numberOfValuesToRead( 0 )
  , m_currentValueIndex( 0 )
  , m_debug( true)
  {   
    m_buffer.showColor( CRGB::Black );

    Serial.begin(9600);
  }

  bool parse_input()
  {
    CRGB color;

    int avail = Serial.available();
    memset( m_input_buffer, 0, Input_Buffer_Length );
    int rb = Serial.readBytes( m_input_buffer,
                               (Input_Buffer_Length > avail ?
                                avail : Input_Buffer_Length ));
    for( int i=0; i<rb; ++i )
    {
      m_debug && Serial.print( "Processing byte  ");
      m_debug && Serial.print( i);
      m_debug && Serial.print( " of ");
      m_debug && Serial.print( rb);
      m_debug && Serial.print( "(");
      m_debug && Serial.print( avail);
      m_debug && Serial.println( " total)");

      // check current byte
      uint8_t c = m_input_buffer[i];

      switch( m_mode )
      {
      case IDLE:
      
        if ( c == MAGIC_NUMBER ) { m_mode = COMMAND; }
        else {       
          m_debug && Serial.println("wrongMagicNumber");
        }
        break;

      
      case COMMAND:

        switch( c )
        {
        case COMMAND_NOP:
          m_debug && Serial.println("COMMAND_NOP");
          m_mode = IDLE;
          break;
        case COMMAND_COLOR:
          m_debug && Serial.println("COMMAND_COLOR");
          m_mode = COLORS_HEAD;
          break;
        case COMMAND_TEST:
          m_debug && Serial.println("COMMAND_TEST");
          testPattern();
          m_mode = IDLE;
          break;
        case COMMAND_TESTRAW:
          m_debug && Serial.println("COMMAND_TESTRAW");
          testPatternRaw();
          m_mode = IDLE;
          break;
        case COMMAND_DEBUG:
          m_debug && Serial.println("COMMAND_DEBUG");
          m_debug = !m_debug;
          m_mode = IDLE;
          break;
        case COMMAND_SINGLE_COLOR:
          m_debug && Serial.println("COMMAND_SINGLE_COLOR");
          m_mode = SINGLE_COLOR;
          break;
        default:
          m_debug && Serial.println("UnknownCommand");
          m_mode = IDLE;
          break;
        }
        break;

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

          m_debug && Serial.println("DoneReading");
        }
        break;
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
    {
      setRGB(buf+3*i, brightness, 0, 0);
    }
    m_buffer.show(); delay(500);
    for( uint8_t i=0; i<NUM_LEDS; ++i)
    {
      setRGB(buf+3*i, 0, brightness, 0);
    }
    m_buffer.show(); delay(500);
    for( uint8_t i=0; i<NUM_LEDS; ++i)
    {
      setRGB(buf+3*i, 0, 0, brightness);
    }
    m_buffer.show(); delay(500);
    for( uint8_t i=0; i<NUM_LEDS; ++i)
    {
      setRGB(buf+3*i, 0, 0, 0);
    }
    m_buffer.show(); delay(500);
  }
  
private:
  char m_input_buffer[ Input_Buffer_Length ];
  Mode m_mode;
  uint16_t m_numberOfValuesToRead;
  uint16_t m_currentValueIndex;

  uint16_t debugcounter;
  Buffer m_buffer;
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
  //command_parser->testPatternRaw(10);
  //command_parser->testPattern();
  //delay(1000);
}
