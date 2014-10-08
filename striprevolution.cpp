#include "CommandParser.h"

// start with 5 LEDs, can be adjusted later
#define NUM_LEDS 5

// this only seems to work if dynamic memory allocation and
// serial initialisation is postponed to init() call in setup()
CommandParser command_parser;

void setup() {
  command_parser.init(NUM_LEDS);
}

void loop() {
  command_parser.parse_input();
}
