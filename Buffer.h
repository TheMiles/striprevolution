// -*- mode: c++ -*-

#include "FastLED.h"

template<class nleds_t=uint8_t, uint8_t DATA_PIN=6, EOrder RGB_ORDER=GRB>
class Buffer
{
public:
  Buffer( nleds_t nleds)
          : m_nleds( nleds)
        {
          m_leds = (CRGB*) calloc( m_nleds ,sizeof( CRGB ) );
          m_data.addLeds<WS2811, DATA_PIN, RGB_ORDER>(m_leds, m_nleds);
          m_data.setBrightness(255);
          m_data.show();
        }

  ~Buffer()
        {
          free(m_leds);
        }
  
  CRGB* leds()
        {
          return m_leds;
        }
  
  uint8_t* leds_raw()
        {
          return reinterpret_cast<uint8_t*>(m_leds);
        }
  
  nleds_t size() const
        {
          return m_nleds;
        }
  
  void showColor( const CRGB& color ) 
        { 
          CRGB* pos = m_leds;
          for( nleds_t i = 0; i < m_nleds; ++i )
              *(pos++) = color;
          m_data.show();
        }

  void showColor( CRGB color, uint8_t brightness )
        {
          color.nscale8_video( brightness );
          showColor( color );
        }

  void show() 
        { 
          m_data.show();
        }

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
  nleds_t  m_nleds;
  CFastLED m_data;
  CRGB*    m_leds;
};
