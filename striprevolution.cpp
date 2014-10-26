#include "CommandParser.h"

#include <avr/wdt.h>

// Default to 5 LEDs, can be adjusted later to a current maximum of 215 LEDs
// The maximum number is limited by the available heap memory for the
// corresponding LED color array of size nleds*3 bytes
#define NUM_LEDS 5

// this only seems to work if dynamic memory allocation and
// serial initialisation are postponed to the init() call in setup()
CommandParser command_parser;

void setup() {
  wdt_disable();
  command_parser.init(NUM_LEDS);
}

void loop() {
  command_parser.parse_input();
}
