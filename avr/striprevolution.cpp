#include "CommandParser.h"

// Default to 5 LEDs which can be adjusted later.
// The maximum number is limited by the available heap memory for the
// corresponding LED color array of size nleds*3 bytes.

#define NUM_LEDS   5
#define STRIP_PIN  6
#define RGB_ORDER  GRB
typedef uint16_t   nleds_t; // uint8_t: max 255, uint16_t: max 65535

#ifdef HAVE_AVR // Standard FastLED buffer with Arduino HardwareSerial

#include "FastLEDBuffer.h"
#include <HardwareSerial.h>

typedef Buffer<nleds_t,STRIP_PIN,RGB_ORDER> LEDBuffer;

typedef HardwareSerial LEDSerial;
HardwareSerial& serial = Serial;

#elif defined(HAVE_TEENSY3) // Standard FastLED buffer


#include "FastLEDBuffer.h"
#include <HardwareSerial.h>

typedef Buffer<nleds_t,STRIP_PIN,RGB_ORDER> LEDBuffer;

typedef HardwareSerial LEDSerial;
HardwareSerial& serial = Serial1;

#else // Dummy Buffer with own serial and main function (EXPERIMENTAL)

#include "BufferBase.h"
#include "AVRSerial.h"
#include "Main.h"

struct RGB
{
  uint8_t red;
  uint8_t green;
  uint8_t blue;
};
typedef BufferBase<nleds_t,RGB> LEDBuffer;

AVRSerial serial;
typedef AVRSerial LEDSerial;
#endif

CommandParser<nleds_t,LEDBuffer,LEDSerial> command_parser(serial);

void setup() {
  command_parser.init(NUM_LEDS);
}

void loop() {
  command_parser.parse_input();
}
