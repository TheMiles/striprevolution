#include "CommandParser.h"

CommandParser *command_parser;

void setup() {
  command_parser = new CommandParser;
}

void loop() {
  command_parser->parse_input();
}
