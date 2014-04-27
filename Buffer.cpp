#include "Buffer.h"

Buffer::Buffer( uint8_t numLeds )
: m_numLeds( numLeds )
, m_leds( NULL )
{
  m_leds = reinterpret_cast< CRGB* >(malloc( m_numLeds * sizeof( CRGB ) ));
  memset( m_leds, 0, m_numLeds * sizeof( CRGB ) );
  m_data.addLeds<WS2811, DATA_PIN, RGB_ORDER>(m_leds, m_numLeds);
  m_data.setBrightness(255);
  m_data.show();
}

Buffer::~Buffer()
{
  free( m_leds );
  m_leds = NULL;
}

CRGB* Buffer::leds() 
{ 
  return m_leds;
}

CFastSPI_LED2* Buffer::data()
{ 
  return &(m_data);
}
  
uint8_t Buffer::size() const
{ 
  return m_numLeds;
}

void Buffer::showColor( const CRGB &color ) 
{ 
  for( uint8_t i = 0; i < m_numLeds; ++i )
  {
    memcpy( m_leds + i, &color, sizeof( CRGB ) );
  }

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

