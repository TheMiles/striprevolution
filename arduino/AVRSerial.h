#ifndef AVRSERIAL_HH
#define AVRSERIAL_HH

#undef BAUD
#define BAUD 9600
#include <util/setbaud.h>
#include <avr/io.h>
#include <stdio.h>

class AVRSerial
{
public:
  AVRSerial()
          : uart_output(
              setup_stream(uart_putchar, NULL, _FDEV_SETUP_WRITE))
          , uart_input(
              setup_stream(NULL, uart_getchar, _FDEV_SETUP_WRITE))
        {}
  
  void begin( unsigned long)
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
  void print( const __FlashStringHelper* s)
        {
          //printf("%s", s);
        }
  
  void println( const __FlashStringHelper* s)
        {
          //printf("%s\n",s);
        }

  void print( const char* s)
        {
          printf("%s", s);
        }
  
  void println( const char* s)
        {
          printf("%s\n",s);
        }

  void print( int s)
        {
          printf("%d", s);
        }
  
  void println( int s)
        {
          printf("%d\n",s);
        }

  void print( unsigned int s)
        {
          printf("%u", s);
        }
  
  void println( unsigned int s)
        {
          printf("%u\n",s);
        }

  void print( char s)
        {
          printf("%c", s);
        }
  
  void println( char s)
        {
          printf("%c\n",s);
        }

  void flush()
        {
          fflush(stdout);
        }
  
  int available()
        {
          return bit_is_set(UCSR0A, RXC0);
        }
  int readBytes(char*, int)
        {
          //int counter = 0;
          return 0;
        }
  
private:
  static int uart_putchar(char c, FILE *stream) {
    if (c == '\n') {
      uart_putchar('\r', stream);
    }
    loop_until_bit_is_set(UCSR0A, UDRE0);
    UDR0 = c;
    return c;
  }
  
  static int uart_getchar(FILE *stream) {
    loop_until_bit_is_set(UCSR0A, RXC0); /* Wait until data exists. */
    return UDR0;
  }
  
  static FILE setup_stream(
      int (*p) (char, FILE*), int (*g)(FILE*), uint8_t f)
	{
          FILE ret = {0};
          ret.put = p;
          ret.get = g;
          ret.flags = f;
          return ret;
        }
  
  FILE uart_output;
  FILE uart_input;
};

#endif
