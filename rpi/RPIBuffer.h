#ifndef RPIBUFFER_H
#define RPIBUFFER_H

#include <stdint.h>
extern "C"
{
#include "ws2811.h"
}

#include <iostream>
#include <stdexcept>

typedef std::runtime_error RPIBufferError;

template<typename nleds_t>
class RPIBuffer
{
public:
  RPIBuffer( nleds_t nleds, uint32_t freq=800000, int dmanum=5, int gpionum=18, int invert=0)
          : m_nleds( nleds)
          , m_initialized(false)
          , m_brightness(0xff)
          , m_leds(0)
        {
          m_leds = new uint8_t[m_nleds*3];
          m_ledstring.freq               = freq;
          m_ledstring.dmanum             = dmanum;
          m_ledstring.channel[0].count   = m_nleds;
          m_ledstring.channel[0].gpionum = gpionum;
          m_ledstring.channel[0].invert  = invert;
          m_ledstring.channel[1].count   = 0;
          m_ledstring.channel[1].gpionum = 0;
          m_ledstring.channel[1].invert  = 0;
          if(ws2811_init(&m_ledstring))
              throw RPIBufferError("Error calling ws2811_init");
          m_initialized = true;
        }

  ~RPIBuffer()
        {
          if( m_initialized)
          {
            clear();
            ws2811_fini(&m_ledstring);
          }
          if( m_leds) delete[] m_leds;
        }
  
  ws2811_led_t* leds()
        {
          return m_ledstring.channel[0].leds;
        }
  
  uint8_t* leds_raw()
        {
          return m_leds;
        }
  
  nleds_t size() const
        {
          return m_nleds;
        }
  
  void showColor( uint8_t red, uint8_t green, uint8_t blue)
        { 
          uint8_t* pos = m_leds;
          for( nleds_t i = 0; i < m_nleds; ++i )
          {
            *(pos++) = red;
            *(pos++) = green;
            *(pos++) = blue;
          }
          
          show();
        }

  void showColor( uint8_t red, uint8_t green, uint8_t blue, uint8_t scale)
        {
          setBrightness(scale);
          showColor( red, green, blue);
        }
  
  void showColor( uint8_t* color ) 
        { 
          showColor( color[0], color[1], color[2]);
        }

  void showColor( uint8_t* color, uint8_t scale)
        { 
          setBrightness( scale);
          showColor(color);
        }

  void show()
        { 
          ws2811_led_t* dest = leds();
          uint8_t*       src = m_leds;
          for( nleds_t i = 0; i < m_nleds; ++i )
          {
            *(dest++) =
                nscale8(*(src),   m_brightness) << 16 |
                nscale8(*(src+1), m_brightness) <<  8 |
                nscale8(*(src+2), m_brightness);
            src += 3;
          }
          if(ws2811_render( &m_ledstring))
              throw RPIBufferError("Error calling ws2811_render");
        }

  void setBrightness(uint8_t brightness )
        {
          m_brightness = brightness;
          show();
        }

  void rainbow()
        {
          show();
        }
  
  void clear()
        {
          showColor( 0, 0, 0);
        }
  
private:
  uint8_t nscale8(uint8_t color, uint8_t scale)
        {
          return (int(color) * int(scale)) >> 8;
        }
    
  nleds_t  m_nleds;
  bool     m_initialized;
  uint8_t  m_brightness;
  
  uint8_t* m_leds;
  ws2811_t m_ledstring;
};

#endif
