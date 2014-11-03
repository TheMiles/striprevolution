#include "CommandParser.h"
#include "Buffer.h"

// Default to 5 LEDs, can be adjusted later to a current maximum of 215 LEDs
// The maximum number is limited by the available heap memory for the
// corresponding LED color array of size nleds*3 bytes
#define NUM_LEDS 5
#define DATA_PIN  6
#define RGB_ORDER GRB                        \

typedef uint16_t nleds_t;
typedef Buffer<nleds_t,DATA_PIN,RGB_ORDER> LEDBuffer;

CommandParser<nleds_t,LEDBuffer,HardwareSerial> command_parser(Serial);

void setup() {
  command_parser.init(NUM_LEDS);
}

void loop() {
  command_parser.parse_input();
}
