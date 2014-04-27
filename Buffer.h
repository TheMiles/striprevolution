

#include "FastSPI_LED2.h"


//const uint8_t NUM_LEDS = 238;
const uint8_t  NUM_LEDS = 255;
const uint8_t  DATA_PIN = 6;
const EOrder   RGB_ORDER = GRB;




class Buffer
{
public:
  Buffer(uint8_t numLeds = NUM_LEDS);

  virtual ~Buffer();

  CRGB* leds();
  CFastSPI_LED2* data();
    
  uint8_t size() const;

  void showColor( const CRGB &color );

  void showColor( CRGB color, uint8_t brightness );
  
  void show();

  void setBrightness(uint8_t brightness );
  void rainbow();


private:
  uint8_t       m_numLeds;
  CRGB*         m_leds;
  CFastSPI_LED2 m_data;
};
