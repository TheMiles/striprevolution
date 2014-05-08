// minicom -b 9600 -D /dev/ttyUSB0
// echo -en "\x42\x01\x01\x0F\x00\x00" > /dev/ttyUSB0
// echo -en "\x42\x01\x05\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF" > /dev/ttyUSB0
// echo -en "\x42\x01\x05\xF\xF\xF\xF\xF\xF\xF\xF\xF\xF\xF\xF\xF\xF\xF" > /dev/ttyUSB0
// echo -e "\x42\x01\x05\x0F\x00\x00" > /dev/ttyUSB0

#include "arduino.h"

#include "CommandParser.h"

CommandParser *command_parser;

void setup() {
  // sanity check delay - allows reprogramming if accidently blowing power w/leds
  delay(2000); 
  command_parser = new CommandParser;
}

void loop() {
  command_parser->parse_input();
}
