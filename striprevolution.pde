// Uncomment this line if you have any interrupts that are changing pins - this causes the library to be a little bit more cautious
// #define FAST_SPI_INTERRUPTS_WRITE_PINS 1

// Uncomment this line to force always using software, instead of hardware, SPI (why?)
// #define FORCE_SOFTWARE_SPI 1

// Uncomment this line if you want to talk to DMX controllers
// #define FASTSPI_USE_DMX_SIMPLE 1

#include "FastSPI_LED2.h"

// echo -e "\x42\x01\x05\x0F\x00\x00" > /dev/ttyUSB0

//const uint8_t NUM_LEDS = 238;
const uint8_t NUM_LEDS = 5;
const uint8_t DATA_PIN = 6;
const EOrder  RGB_ORDER = GRB;

const int Input_Buffer_Length = 64;

const uint8_t MAGIC_NUMBER      = 0x42;
const uint8_t COMMAND_NOP       = 0x00;
const uint8_t COMMAND_SEQUENCE  = 0x01;
const uint8_t COMMAND_COLOR     = 0x02;


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
  void show() { m_data.show(); }


private:

  uint8_t       m_numLeds;
  CRGB*         m_leds;
  CFastSPI_LED2 m_data;
};

class DoubleBuffer
{
public:
  DoubleBuffer( uint8_t numLeds = NUM_LEDS)
  : m_front( 0 )
  {
    m_buffers[0] = Buffer(numLeds);
    m_buffers[1] = Buffer(numLeds);
  }

  Buffer* front() { return &m_buffers[m_front]; }
  Buffer* back() { return &m_buffers[m_front^1]; }

  CRGB* frontLeds() { return front()->leds(); }
  CRGB* backLeds() { return back()->leds(); }

  void swapBuffers() { m_front = m_front ^ 1; show(); }
  void show( Buffer* buffer = NULL) { 
    if( !buffer ) { buffer = front(); }
    buffer->show();
  }

  void showColor( CRGB const &color ) {
  
    uint8_t* colorValues = reinterpret_cast< uint8_t* >( backLeds() );
    for( uint8_t i = 0; i < NUM_LEDS; ++i )
    {
      memcpy( colorValues + i * sizeof( CRGB ), &color, sizeof( CRGB ) );
    }

    swapBuffers();
  }

  void error( uint8_t errorCode )
  {
    Buffer *buffer = front();

    buffer->showColor( CRGB::Black );
    delay(125);
    buffer->showColor( CRGB::Red );
    delay(125);
    buffer->showColor( CRGB::Black );
    delay(125);
    buffer->showColor( CRGB::Red );
    delay(125);
    buffer->showColor( CRGB::Black );
    delay(500);

    for( uint8_t i=0; i<errorCode; ++i )
    {
      buffer->showColor( CRGB::Blue );
      delay(500);
      buffer->showColor( CRGB::Black );
      delay(250);
    }

    buffer->showColor( CRGB::Green );
    delay(1000);
    buffer->showColor( CRGB::Black );
    delay(1000);


  }

private:

  uint8_t m_front;
  Buffer m_buffers[2];

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
  {   
    m_buffers.showColor( CRGB::Black );

    Serial.begin(9600);
  }

  bool parse_input()
  {
    CRGB color;

    int avail = Serial.available();
    memset( m_input_buffer, 0, Input_Buffer_Length );

    avail = Serial.readBytes( m_input_buffer, avail );

    for( int i=0; i<avail; ++i )
    {
      // check current byte
      uint8_t c = m_input_buffer[i];

      switch( m_mode )
      {
      case IDLE:
      
        if ( c == MAGIC_NUMBER ) { m_mode = COMMAND; }
        else {       
          Serial.println("wrongMagicNumber");
        }
        break;

      
      case COMMAND:

        switch( c )
            {
        case COMMAND_NOP:       m_mode = IDLE; break;
        case COMMAND_SEQUENCE:  m_mode = COLORS_HEAD; break;
        case COMMAND_COLOR:     m_mode = SINGLE_COLOR; break;
        default:                m_mode = IDLE; Serial.println("UnknownCommand"); break;
        }
        break;

      case SINGLE_COLOR:

        memcpy( &color, m_input_buffer + i, 3 );
        i = i + 3;
        m_buffers.showColor( color );

        Serial.print(" SINGLE_COLOR ");
        Serial.print( i );
        Serial.print( " color ");
        Serial.print( color[0] );
        Serial.print(", ");
        Serial.print( color[1] );
        Serial.print(", ");
        Serial.print( color[2] );
        Serial.println( " " );

        break;

      case COLORS_HEAD:
        m_numberOfValuesToRead = c * 3;
        m_currentValueIndex = 0;
        m_mode = COLORS_READ;
        debugcounter = 0;
        break;

      case COLORS_READ:
        uint8_t* colorValues      = reinterpret_cast< uint8_t* >(m_buffers.backLeds());
        uint8_t  valuesAvailable  = avail - i;
        uint8_t  valuesLeft       = m_numberOfValuesToRead - m_currentValueIndex;
        uint8_t  valuesToRead     = (valuesAvailable < valuesLeft) ? valuesAvailable : valuesLeft;

        Serial.print( debugcounter++ );
        Serial.print(" Read LED ");
        Serial.print( valuesToRead );
        Serial.print(" index ");
        Serial.print( m_currentValueIndex );
        Serial.print(" i ");
        Serial.print( i );

        size_t copyNumber = static_cast< size_t >( valuesToRead );

        memcpy( colorValues + m_currentValueIndex, m_input_buffer + i, copyNumber );

        m_currentValueIndex  = m_currentValueIndex + valuesToRead;
        i                    = i + valuesToRead;


        Serial.print(" AFTER ");
        Serial.print( valuesToRead );
        Serial.print( " numberofvalues ");
        Serial.print( m_numberOfValuesToRead );
        Serial.print(" index ");
        Serial.print( m_currentValueIndex );
        Serial.print(" i ");
        Serial.println( i );


        if( m_currentValueIndex >= m_numberOfValuesToRead )
        {
          m_buffers.swapBuffers();
          m_mode = IDLE;

          Serial.println("DoneReading");
        }
        break;
      }
    }
  }

  
private:
  char m_input_buffer[ Input_Buffer_Length ];
  Mode m_mode;
  uint16_t m_numberOfValuesToRead;
  uint16_t m_currentValueIndex;

  uint16_t debugcounter;
  DoubleBuffer m_buffers;
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

