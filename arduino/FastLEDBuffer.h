// -*- mode: c++ -*-
#ifndef FASTLEDBUFFER_H
#define FASTLEDBUFFER_H

#include "FastLED.h"

#include "BufferBase.h"

template<typename nleds_t=uint8_t, uint8_t DATA_PIN=6, EOrder RGB_ORDER=GRB>
class Buffer : public BufferBase<nleds_t,CRGB>
{
  typedef BufferBase<nleds_t,CRGB> Base;
  
public:
  Buffer()
        {}

  void init( nleds_t nleds)
        {
          Base::init(nleds);
          m_data.addLeds<WS2811, DATA_PIN, RGB_ORDER>(
              Base::m_leds, Base::m_nleds);
          m_data.setBrightness(255);
          show();
        }

  void showColor( uint8_t red, uint8_t green, uint8_t blue) 
        { 
          Base::showColor(red,green,blue);
          show();
        }

  void showColor( const CRGB& color ) 
        { 
          Base::showColor(color);
          show();
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
          fill_rainbow(Base::leds(), Base::size(), 0, uint8_t(255/Base::size()) );
          show();
        }

  void clear()
        {
          Base::clear();
          show();
        }
  
private:
  CFastLED m_data;
};

#endif
