#include "Buffer.h"

Buffer::Buffer( uint8_t numLeds )
: m_numLeds( numLeds )
{
  m_leds = new CRGB(m_numLeds);
  memset( m_leds, 0, m_numLeds * sizeof( CRGB ) );
  m_data.addLeds<WS2811, DATA_PIN, RGB_ORDER>(m_leds, m_numLeds);
  m_data.setBrightness(255);
  m_data.show();
}

Buffer::~Buffer()
{
  delete[] m_leds;
}

CRGB* Buffer::leds() 
{ 
  return m_leds;
}

CFastLED* Buffer::data()
{ 
  return &(m_data);
}
  
uint8_t Buffer::size() const
{ 
  return m_numLeds;
}

void Buffer::showColor( const CRGB& color ) 
{ 
  CRGB* pos = m_leds;
  for( uint8_t i = 0; i < m_numLeds; ++i )
      *(pos++) = color;
  m_data.show();
}

void Buffer::showColor( CRGB color, uint8_t brightness )
{
  color.nscale8_video( brightness );
  showColor( color );
}

void Buffer::show() 
{ 
  m_data.show();
}

void Buffer::setBrightness(uint8_t brightness )
{
  m_data.show(brightness);
}

void Buffer::rainbow()
{
  fill_rainbow(leds(), size(), 0, uint8_t(255/size()) );
  m_data.show();
}

