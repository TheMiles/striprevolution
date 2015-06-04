#include "CommandParser.h"
#include "SerialSelector.h"

// Default to 5 LEDs which can be adjusted later.
// The maximum number is limited by the available heap memory for the
// corresponding LED color array of size nleds*3 bytes.

#define NUM_LEDS   5
#define RGB_ORDER  GRB
typedef uint16_t   nleds_t; // uint8_t: max 255, uint16_t: max 65535



#ifdef XBEE
#include "XBeeSerial.h"
typedef XBeeSerial LEDSerial;
LEDSerial serial;
#else
typedef serial_t LEDSerial;
LEDSerial& serial = Serial;	
#endif

#include "FastLEDBuffer.h"
typedef Buffer<nleds_t,STRIP_PIN,RGB_ORDER> LEDBuffer;

CommandParser<nleds_t,LEDBuffer,LEDSerial> command_parser(serial);

void setup() {
  command_parser.init(NUM_LEDS);
}

void loop() {
  command_parser.parse_input();
}
