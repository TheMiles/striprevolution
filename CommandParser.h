#include "Buffer.h"

#define STR_HELPER(x) #x
#define STR(x) STR_HELPER(x)

#define LOG_BUFSIZE   128
#define INPUT_BUFSIZE 128
#define BAUDRATE      115200

#define MAGIC 0x42

#define DATA_PIN  6
#define RGB_ORDER GRB                        \

class CommandParser
{
  typedef Buffer<DATA_PIN,RGB_ORDER> LEDBuffer;
  
public:

  enum Command
  {
      COMMAND_NOP          = 0x0,
      COMMAND_COLOR        = 0x1,
      COMMAND_UNICOLOR     = 0x2,
      COMMAND_SINGLE_COLOR = 0x3,
      COMMAND_BRIGHT       = 0x4,
      COMMAND_RAINBOW      = 0x5,
      COMMAND_STATE        = 0x6,
      COMMAND_TEST         = 0x61,
      COMMAND_TESTRAW      = 0x62,
      COMMAND_CONF         = 0x67,
      COMMAND_DEBUG        = 0x68,
      COMMAND_RESET        = 0x69,
      COMMAND_SETSIZE      = 0x70,
      COMMAND_SPEEDTEST    = 0x71,
      COMMAND_MEMFREE      = 0x72,
  };

  enum Mode
  {
    IDLE,
    COMMAND,
    COLORS_HEAD,
    COLORS_READ,
    SINGLE_COLOR,
    COLORS_ALL,
    SET_BRIGHT,
    SET_SIZE,
    MODE_MAX
  };

  static const char* ModeText[MODE_MAX];

  enum LogLvl
  {
    ERROR,
    INFO,
    DEBUG,
    LOGLVL_MAX
  };

  static const char* LogLvlText[LOGLVL_MAX];

  CommandParser();
  ~CommandParser();
  
  void init(uint8_t nleds);
  
  void log_msg( LogLvl log_level, const char * format_string, ... ) const;

  void setMode( Mode new_mode );

  Mode mode() const;

  void parse_input();
  
  void testPattern( uint8_t brightness=255);

  void setRGB( uint8_t* data, uint8_t r, uint8_t g, uint8_t b);
  
  void testPatternRaw( uint8_t brightness=255);
  
private:
  LEDBuffer* m_buffer;

  Mode m_mode;
  LogLvl m_logLevel;
  mutable char m_log_buffer[LOG_BUFSIZE];
  char m_input_buffer[INPUT_BUFSIZE];

  unsigned int m_numberOfValuesToRead;
  unsigned int m_currentValueIndex;
};
