// Uncomment this line if you have any interrupts that are changing pins - this causes the library to be a little bit more cautious
// #define FAST_SPI_INTERRUPTS_WRITE_PINS 1

// Uncomment this line to force always using software, instead of hardware, SPI (why?)
// #define FORCE_SOFTWARE_SPI 1

// Uncomment this line if you want to talk to DMX controllers
// #define FASTSPI_USE_DMX_SIMPLE 1

#include "FastSPI_LED2.h"


// long      previous_timestamp  = 0;
// long      base_delay          = 10;

// class CommandParser
// {
// public:

//   typedef void(*ValueChangedCBK)(int, int);
//   typedef void(*UpdateFinishedCBK)(void);
  
  

//   CommandParser()  
//   : m_command('n')
//   , m_number(0)
//   , m_idle_counter(0)
//   , m_active_color(0)
//   , m_active_channel(0)
//   , m_update_needed(false)
//   , m_value_changed_function(NULL)
//   , m_update_finished_function(NULL)
//   {        
//     Serial.begin(9600);
//   }

//   void handle_command()
//   {
//     if( m_command != 'n' )
//     {
//       switch( m_command )
//       {
//       case 'c':
//         m_active_channel = constrain( m_number, 0, Num_Channels  );
//         break;
//       case 'v':
//         m_active_color = constrain( m_number, 0, Max_Value );
//         if( m_value_changed_function )
//         {
//           m_value_changed_function( m_active_channel, m_active_color );
//           m_update_needed = true;
//         }
        
//         break;
//       default:
//         break;
//       }
      
//       m_number = 0;
//     }
//   }


//   bool parse_input()
//   {
//     m_update_needed = false;

//     int avail = Serial.available();
//     memset( m_input_buffer, 0, Input_Buffer_Length );
//     Serial.readBytes( m_input_buffer, avail );
    
//     if( avail > 0 )
//     {
//       m_idle_counter = 0;
      
//       bool found   = false;
//       char new_command = 'n';
//       char c;
      
//       for( int i=0; i<avail; ++i )
//       {
//         // check current byte
//         c = m_input_buffer[i];

//         if( c >= 0x30 && c<= 0x39 )
//         {
//           // digit adds up to the current number
//           int digit = c - 0x30;        // get digit value
//           m_number = m_number * 10 + digit;// shift number and add digit
//         }
//         else
//         {
//           // in all other cases we think this must be a command
//           new_command = c;
//           found = true;
//         }
        
//         if( found )
//         {
//           handle_command();
//           m_command = new_command;
//           found = false;
//         }
//       }
//     }
//     else
//     {
//       ++m_idle_counter;
//       if( m_idle_counter == 1 )
//       {
//         handle_command();
//         m_command = 'n';
//       }
//     }

//     if( m_update_needed && m_update_finished_function )
//     {
//       m_update_finished_function();
//     }
//   }

//   void setValueChangedCallback( ValueChangedCBK callback )
//   {
//     m_value_changed_function = callback;
//   }

//   void setUpdateFinishedCallback( UpdateFinishedCBK callback )
//   {
//     m_update_finished_function = callback;
//   }
  
// private:
//   char m_input_buffer[ Input_Buffer_Length ];
//   char m_command;
//   int  m_number;
//   int  m_idle_counter;
//   int  m_active_color; // values range [0..255]
//   int  m_active_channel;
//   bool m_update_needed;
//   ValueChangedCBK m_value_changed_function;
//   UpdateFinishedCBK m_update_finished_function;
  
// };

// CommandParser *command_parser;


// void tlc_setter( int channel, int value)
// {
//   Tlc.set(channel, value);
// }

// void tlc_updater()
// {
//   Tlc.update();
// }





// // the setup routine runs once when you press reset:
// void setup() 
// {        
//   Tlc.init();
//   command_parser = new CommandParser();
//   command_parser->setValueChangedCallback( tlc_setter );
//   command_parser->setUpdateFinishedCallback( tlc_updater );
  
  
// }

// // the loop routine runs over and over again forever:
// void loop() 
// {
//   long current_timestamp = millis();
//   if( current_timestamp - previous_timestamp > base_delay )
//   {
//      previous_timestamp = current_timestamp;
//      command_parser->parse_input();
//   }
// }

////////////////////////////////////////////////////////////////////////////////////////////////////
//
// FastSPI example code
//
//////////////////////////////////////////////////

#define NUM_LEDS 238

CRGB leds[NUM_LEDS];

void setup() {
  // sanity check delay - allows reprogramming if accidently blowing power w/leds
    delay(2000);

    // For safety (to prevent too high of a power draw), the test case defaults to
    // setting brightness to 25% brightness
    LEDS.setBrightness(64);

    // LEDS.addLeds<WS2811, 13>(leds, NUM_LEDS);
    // LEDS.addLeds<TM1809, 13>(leds, NUM_LEDS);
    // LEDS.addLeds<UCS1903, 13>(leds, NUM_LEDS);
    // LEDS.addLeds<TM1803, 13>(leds, NUM_LEDS);

    // LEDS.addLeds<P9813>(leds, NUM_LEDS);
    
    // LEDS.addLeds<LPD8806>(leds, NUM_LEDS);
    // LEDS.addLeds<WS2801>(leds, NUM_LEDS);
    // LEDS.addLeds<SM16716>(leds, NUM_LEDS);

    LEDS.addLeds<WS2811, 6>(leds, NUM_LEDS);

    // Put ws2801 strip on the hardware SPI pins with a BGR ordering of rgb and limited to a 1Mhz data rate
    // LEDS.addLeds<WS2801, 11, 13, BGR, DATA_RATE_MHZ(1)>(leds, NUM_LEDS);

    // LEDS.addLeds<LPD8806, 10, 11>(leds, NUM_LEDS);
    // LEDS.addLeds<WS2811, 13, BRG>(leds, NUM_LEDS);
    // LEDS.addLeds<LPD8806, BGR>(leds, NUM_LEDS);
}

void loop() { 
  for(int i = 0; i < 3; i++) {
    for(int iLed = 0; iLed < NUM_LEDS; iLed++) {
      memset(leds, 0,  NUM_LEDS * sizeof(struct CRGB));

      switch(i) { 
        // You can access the rgb values by field r, g, b
        case 0: leds[iLed].r = 128; break;

        // or by indexing into the led (r==0, g==1, b==2) 
        case 1: leds[iLed][i] = 128; break;

        // or by setting the rgb values for the pixel all at once
        case 2: leds[iLed] = CRGB(0, 0, 128); break;
      }

      // and now, show your led array! 
      LEDS.show();
      delay(10);
    }

    // fade up
    for(int x = 0; x < 128; x++) { 
      // The showColor method sets all the leds in the strip to the same color
      LEDS.showColor(CRGB(x, 0, 0));
      delay(10);
    }

    // fade down
    for(int x = 128; x >= 0; x--) { 
      LEDS.showColor(CRGB(x, 0, 0));
      delay(10);
    }

    // let's fade up by scaling the brightness
    for(int scale = 0; scale < 128; scale++) { 
      LEDS.showColor(CRGB(0, 128, 0), scale);
      delay(10);
    }

    // let's fade down by scaling the brightness
    for(int scale = 128; scale > 0; scale--) { 
      LEDS.showColor(CRGB(0, 128, 0), scale);
      delay(10);
    }
  }
}

