/*
    Basic Pin setup:
    ------------                                  ---u----
    ARDUINO   13|-> SCLK (pin 25)           OUT1 |1     28| OUT channel 0
              12|                           OUT2 |2     27|-> GND (VPRG)
              11|-> SIN (pin 26)            OUT3 |3     26|-> SIN (pin 11)
              10|-> BLANK (pin 23)          OUT4 |4     25|-> SCLK (pin 13)
               9|-> XLAT (pin 24)             .  |5     24|-> XLAT (pin 9)
               8|                             .  |6     23|-> BLANK (pin 10)
               7|                             .  |7     22|-> GND
               6|                             .  |8     21|-> VCC (+5V)
               5|                             .  |9     20|-> 2K Resistor -> GND
               4|                             .  |10    19|-> +5V (DCPRG)
               3|-> GSCLK (pin 18)            .  |11    18|-> GSCLK (pin 3)
               2|                             .  |12    17|-> SOUT
               1|                             .  |13    16|-> XERR
               0|                           OUT14|14    15| OUT channel 15
    ------------                                  --------

    -  Put the longer leg (anode) of the LEDs in the +5V and the shorter leg
         (cathode) in OUT(0-15).
    -  +5V from Arduino -> TLC pin 21 and 19     (VCC and DCPRG)
    -  GND from Arduino -> TLC pin 22 and 27     (GND and VPRG)
    -  digital 3        -> TLC pin 18            (GSCLK)
    -  digital 9        -> TLC pin 24            (XLAT)
    -  digital 10       -> TLC pin 23            (BLANK)
    -  digital 11       -> TLC pin 26            (SIN)
    -  digital 13       -> TLC pin 25            (SCLK)
    -  The 2K resistor between TLC pin 20 and GND will let ~20mA through each
       LED.  To be precise, it's I = 39.06 / R (in ohms).  This doesn't depend
       on the LED driving voltage.
    - (Optional): put a pull-up resistor (~10k) between +5V and BLANK so that
                  all the LEDs will turn off when the Arduino is reset.

    If you are daisy-chaining more than one TLC, connect the SOUT of the first
    TLC to the SIN of the next.  All the other pins should just be connected
    together:
        BLANK on Arduino -> BLANK of TLC1 -> BLANK of TLC2 -> ...
        XLAT on Arduino  -> XLAT of TLC1  -> XLAT of TLC2  -> ...
    The one exception is that each TLC needs it's own resistor between pin 20
    and GND.

    This library uses the PWM output ability of digital pins 3, 9, 10, and 11.
    Do not use analogWrite(...) on these pins.

*/

#include "Tlc5940.h"


const int Input_Buffer_Length = 64;
const int Num_Channels        = 15;
const int Max_Value           = 4095;

long      previous_timestamp  = 0;
long      base_delay          = 10;

class CommandParser
{
public:

  typedef void(*UpdateChannelCBK)(int, int);
  

  CommandParser()  
  : m_updateFunction(NULL)
  , m_command('n')
  , m_number(0)
  , m_idle_counter(0)
  , m_active_color(0)
  , m_active_channel(0)
  {        
    Serial.begin(9600);
  }

void handle_command()
{
  if( m_command != 'n' )
  {
    switch( m_command )
    {
    case 'c':
      m_active_channel = constrain( m_number, 0, Num_Channels  );
      break;
    case 'v':
      m_active_color = constrain( m_number, 0, Max_Value );
      if( m_updateFunction )
          m_updateFunction( m_active_channel, m_active_color );
      break;
    default:
      break;
    }
    
    m_number = 0;
  }
}


bool parse_input()
{
  int avail = Serial.available();
  memset( m_input_buffer, 0, Input_Buffer_Length );
  Serial.readBytes( m_input_buffer, avail );
  
  if( avail > 0 )
  {
    m_idle_counter = 0;
    
    bool found   = false;
    char new_command = 'n';
    char c;
    
    for( int i=0; i<avail; ++i )
    {
      // check current byte
      c = m_input_buffer[i];

      if( c >= 0x30 && c<= 0x39 )
      {
        // digit adds up to the current number
        int digit = c - 0x30;        // get digit value
        m_number = m_number * 10 + digit;// shift number and add digit
      }
      else
      {
        // in all other cases we think this must be a command
        new_command = c;
        found = true;
      }
      
      if( found )
      {
        handle_command();
        m_command = new_command;
        found = false;
      }
    }
  }
  else
  {
    ++m_idle_counter;
    if( m_idle_counter == 1 )
    {
      handle_command();
      m_command = 'n';
    }
  }
}

  void setUpdateCallback( UpdateChannelCBK callback )
  {
    m_updateFunction = callback;
  }
  
private:
  char m_input_buffer[ Input_Buffer_Length ];
  char m_command;
  int  m_number;
  int  m_idle_counter;
  int  m_active_color; // values range [0..255]
  int  m_active_channel;
  UpdateChannelCBK m_updateFunction;
};

CommandParser *command_parser;


void tlc_updater( int channel, int value)
{
  Tlc.set(channel, value);
  Tlc.update();
}




// the setup routine runs once when you press reset:
void setup() 
{        
  Tlc.init();
  command_parser = new CommandParser();
  command_parser->setUpdateCallback( tlc_updater );
  
}

// the loop routine runs over and over again forever:
void loop() 
{
  long current_timestamp = millis();
  if( current_timestamp - previous_timestamp > base_delay )
  {
     previous_timestamp = current_timestamp;
     command_parser->parse_input();
  }
}
