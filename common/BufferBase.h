// -*- mode: c++ -*-
#ifndef BUFFERBASE_H
#define BUFFERBASE_H

template<typename nleds_t,typename pixel_t>
class BufferBase
{
public:
  BufferBase()
          : m_nleds(0)
          , m_leds(0)
        {}

  void init( nleds_t nleds)
        {
          free();
          m_leds = (pixel_t*) calloc(nleds,sizeof(pixel_t));
          m_nleds = nleds;
        }

  void free()
        {
          if( m_leds)
              ::free(m_leds);
        }

  pixel_t* leds()
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
  
  void showColor( uint8_t red, uint8_t green, uint8_t blue )
        {
          pixel_t tmp;
          tmp.red   = red;
          tmp.green = green;
          tmp.blue  = blue;
          showColor( tmp);
        }
  
  void showColor( const pixel_t& color ) 
        { 
         pixel_t* pos = m_leds;
          for( nleds_t i = 0; i < m_nleds; ++i )
              *(pos++) = color;
        }

  void clear()
        {
          memset( m_leds, 0, sizeof(m_leds)*m_nleds);
        }
  
  void rainbow()
        {}
  void setBrightness( uint8_t)
        {}
  void show()
        {}
  
protected:
  nleds_t  m_nleds;
  pixel_t* m_leds;
};

#endif
