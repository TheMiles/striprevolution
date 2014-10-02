#include "Buffer.h"

#define LOG_BUFSIZE   128
#define INPUT_BUFSIZE 128

#define MAGIC 0x42

class CommandParser
{
public:

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

  enum Command
  {
      COMMAND_NOP          = 0x0,
      COMMAND_COLOR        = 0x1,
      COMMAND_UNICOLOR     = 0x2,
      COMMAND_SINGLE_COLOR = 0x3,
      COMMAND_BRIGHT       = 0x4,
      COMMAND_RAINBOW      = 0x5,
      COMMAND_TEST         = 0x61,
      COMMAND_TESTRAW      = 0x62,
      COMMAND_CONF         = 0x67,
      COMMAND_DEBUG        = 0x68,
      COMMAND_RESET        = 0x69,
      COMMAND_SETSIZE      = 0x70,
  };

  enum LogLevel
  {
    INFO,
    ERROR,
    CHATTY,
    DEBUG,
  };

  CommandParser();

  void log_msg( LogLevel log_level, const char * format_string, ... ) const;

  void setMode( Mode new_mode );

  Mode mode() const;

  void parse_input();
  
  void testPattern( uint8_t brightness=255);

  void setRGB( uint8_t* data, uint8_t r, uint8_t g, uint8_t b);
  
  void testPatternRaw( uint8_t brightness=255);
  
private:
  Mode m_mode;
  uint16_t m_numberOfValuesToRead;
  uint16_t m_currentValueIndex;

  Buffer m_buffer;
  LogLevel m_logLevel;
};
