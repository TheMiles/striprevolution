// Uncomment this line if you have any interrupts that are changing pins - this causes the library to be a little bit more cautious
// #define FAST_SPI_INTERRUPTS_WRITE_PINS 1

// Uncomment this line to force always using software, instead of hardware, SPI (why?)
// #define FORCE_SOFTWARE_SPI 1

// Uncomment this line if you want to talk to DMX controllers
// #define FASTSPI_USE_DMX_SIMPLE 1

#include "FastSPI_LED2.h"

const uint8_t NUM_LEDS = 238;
const uint8_t DATA_PIN = 6;

const int Input_Buffer_Length = 64;
const int Num_Channels        = 15;
const int Max_Value           = 4095;

const uint8_t MAGIC_NUMBER  = 0x42;
const uint8_t COMMAND_NOP   = 0x00;
const uint8_t COMMAND_COLOR = 0x01;

const CRGB BLACK = CRGB(  0,   0,   0);
const CRGB WHITE = CRGB(255, 255, 255);
const CRGB RED   = CRGB(255,   0,   0);
const CRGB GREEN = CRGB(  0, 255,   0);
const CRGB BLUE  = CRGB(  0,   0, 255);

class Buffer
{
public:
  Buffer(uint8_t numLeds = NUM_LEDS)
  : m_numLeds( numLeds )
  , m_leds( NULL )
  {
    m_leds = reinterpret_cast< CRGB* >(malloc( m_numLeds * sizeof( CRGB ) ));

    m_data.setBrightness(255);
    m_data.addLeds<WS2811, 6>(m_leds, m_numLeds);
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
  DoubleBuffer( uint8_t numLeds )
  : m_front( 0 )
  , m_buffers{Buffer(numLeds), Buffer(numLeds)}
  {}

  Buffer* front() { return &m_buffers[m_front]; }
  Buffer* back() { return &m_buffers[m_front^1]; }

  CRGB* frontLeds() { return front()->leds(); }
  CRGB* backLeds() { return back()->leds(); }

  void swapBuffers() { m_front = m_front ^ 1; show(); }
  void show( Buffer* buffer = NULL) { 
    if( !buffer ) { buffer = front(); }
    buffer->show();
  }

  void error( uint8_t errorCode )
  {
    Buffer *buffer = front();

    buffer->showColor( BLACK );
    delay(125);
    buffer->showColor( RED );
    delay(125);
    buffer->showColor( BLACK );
    delay(125);
    buffer->showColor( RED );
    delay(125);
    buffer->showColor( BLACK );
    delay(500);

    for( uint8_t i=0; i<0; ++i )
    {
      buffer->showColor( BLUE );
      delay(500);
      buffer->showColor( BLACK );
      delay(250);
    }

    buffer->showColor( GREEN );
    delay(1000);
    buffer->showColor( BLACK );
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
  };

  CommandParser()  
  : m_mode(IDLE)
  , m_buffers( NUM_LEDS )
  , m_numberOfLedsToRead( 0 )
  , m_currentLed(0)
  , m_currentColor(0)
  {        
    Serial.begin(9600);
  }

  bool parse_input()
  {
    int avail = Serial.available();
    memset( m_input_buffer, 0, Input_Buffer_Length );
    Serial.readBytes( m_input_buffer, avail );

    for( int i=0; i<avail; ++i )
    {
      // check current byte
      uint8_t c = m_input_buffer[i];

      switch( m_mode )
      {
      case IDLE:
      
        if ( c == MAGIC_NUMBER ) { m_mode = COMMAND; }
        else { m_buffers.error(1); }
        break;

      
      case COMMAND:

        switch( c )
        {
        case COMMAND_NOP:   m_mode = IDLE; break;
        case COMMAND_COLOR: m_mode = COLORS_HEAD; break;
        default:            m_mode = IDLE; m_buffers.error(2); break;
        }
        break;

      case COLORS_HEAD:
        m_numberOfLedsToRead = c;
        m_currentLed = 0;
        m_currentColor = 0;
        m_mode = COLORS_READ;
        break;

      case COLORS_READ:
        m_buffers.backLeds()[m_currentLed][m_currentColor] = c;

        ++m_currentColor;
        if( m_currentColor >= 3 )
        {
          m_currentColor = 0;

          ++m_currentLed;
          if( m_currentLed >= m_numberOfLedsToRead || m_currentLed >= NUM_LEDS )
          {
            m_currentLed = 0;

            m_buffers.swapBuffers();
            m_mode = IDLE;
          }
        }
        break;
      }
    }
  }

  
private:
  char m_input_buffer[ Input_Buffer_Length ];
  Mode m_mode;
  uint8_t m_numberOfLedsToRead;
  uint8_t m_currentLed;
  uint8_t m_currentColor;

  DoubleBuffer m_buffers;
};

CommandParser *command_parser;


void setup() {
  // sanity check delay - allows reprogramming if accidently blowing power w/leds
  delay(2000);

  command_parser = new CommandParser();

}

void loop() { 
  command_parser->parse_input();
}

