#ifndef AVRSERIAL_HH
#define AVRSERIAL_HH

#undef BAUD
#define BAUD BAUDRATE
#include <util/setbaud.h>

class AVRSerial
{
public:
  AVRSerial()
        {}
  
  void begin( int)
        {
          UBRR0H = UBRRH_VALUE;
          UBRR0L = UBRRL_VALUE;
// #if USE_2X
//           UCSR0A |= (1 << U2X);
// #else
//           UCSR0A &= ~(1 << U2X);
// #endif
          UCSR0C = _BV(UCSZ01) | _BV(UCSZ00); /* 8-bit data */
          UCSR0B = _BV(RXEN0) | _BV(TXEN0);   /* Enable RX and TX */

          stdout = &uart_output;
          stdin  = &uart_input;

        }
  void print( const char* s)
        {
          printf("%s");
        }
  
  void println( const char* s)
        {
          printf("%s\n");
        }

private:
  static void uart_putchar(char c, FILE *stream) {
    if (c == '\n') {
      uart_putchar('\r', stream);
    }
    loop_until_bit_is_set(UCSR0A, UDRE0);
    UDR0 = c;
  }
  
  static char uart_getchar(FILE *stream) {
    loop_until_bit_is_set(UCSR0A, RXC0); /* Wait until data exists. */
    return UDR0;
  }
  
  static FILE uart_output;
  static FILE uart_input;
};

FILE* AVRSerial::uart_output( FDEV_SETUP_STREAM(uart_putchar, NULL, _FDEV_SETUP_WRITE));
FILE* AVRSerial::uart_input(  FDEV_SETUP_STREAM(NULL, uart_getchar, _FDEV_SETUP_READ));

#endif
