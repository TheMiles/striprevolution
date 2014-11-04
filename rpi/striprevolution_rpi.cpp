#include "RPIBuffer.h"
#include "RPISerial.h"
#include "CommandParser.h"

#include <cstdlib>
#include <cstdio>
#include <signal.h>
#include <string>

#define NUM_LEDS 5

typedef uint8_t nleds_t;
typedef RPIBuffer<nleds_t> LEDBuffer;

bool doIterate = true;

void sig_handler(int signo) 
{
  doIterate = false;
}

int main( int argc, char** argv) {
  struct sigaction sa;
  memset( &sa, 0, sizeof(sa) );
  sa.sa_handler = &sig_handler;
  sigfillset(&sa.sa_mask);
  sigaction(SIGINT, &sa, NULL);
  try
  {
    std::string filename = "/dev/ttyAMA0";
    if( argc > 1)
        filename = argv[1];
    
    printf( "Using %s\n", filename.c_str());
    RPISerial serial(filename.c_str());
    CommandParser<nleds_t,LEDBuffer,RPISerial> command_parser(serial);
    command_parser.init(NUM_LEDS);
    while(doIterate)
        command_parser.parse_input();
  }
  catch( const std::runtime_error& err)
  {
    std::cout << err.what() << std::endl;
    return 1;
  }
  
  return 0;
}
