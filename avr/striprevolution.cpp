#include "CommandParser.h"
#include "SerialSelector.h"

// Default to 5 LEDs which can be adjusted later.
// The maximum number is limited by the available heap memory for the
// corresponding LED color array of size nleds*3 bytes.

#define NUM_LEDS   5
#define RGB_ORDER  GRB
typedef uint16_t   nleds_t; // uint8_t: max 255, uint16_t: max 65535

#if defined (HAVE_AVR)
#define STRIP_PIN  6
#elif defined(HAVE_TEENSY3)
#define STRIP_PIN  2
#endif // HAVE_TEENSY3


#if defined(XBEE)
LEDSerial serial;
#else //XBEE
LEDSerial& serial = Serial;	
#endif //XBEE

#include "FastLEDBuffer.h"
typedef Buffer<nleds_t,STRIP_PIN,RGB_ORDER> LEDBuffer;

CommandParser<nleds_t,LEDBuffer,LEDSerial> command_parser(serial);

void setup() {
  command_parser.init(NUM_LEDS);
}

void loop() {
  command_parser.parse_input();
}
