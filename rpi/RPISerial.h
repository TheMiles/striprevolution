#ifndef RPISERIAL_H
#define RPISERIAL_H

#include <cstring>
#include <cerrno>
#include <cstdio>
#include <fcntl.h>
#include <termios.h>

#include <sstream>

#define BUFSIZE 128

#if BAUDRATE == 9600
#define TC_BAUDRATE B9600
#else
#define TC_BAUDRATE B115200
#endif


typedef std::runtime_error RPISerialError;
    
class RPISerial
{
  static void throwError( const char* caller)
        {
            std::ostringstream oss;
            oss << "Error " << errno << " from " << caller << ": " << strerror(errno);
            throw RPISerialError( oss.str());
        }
  
public:
  RPISerial( const char* device)
  : m_valid(0)
        {
          m_fd = open( device, O_RDWR| O_NOCTTY );
          if( m_fd < 0)
              throwError("open");
        }
  
  ~RPISerial()
        {
          if( m_fd > 0)
              close( m_fd);
        }
  
  void begin( int baudrate)
        {
          struct termios tty;
          struct termios tty_old;
          memset (&tty, 0, sizeof tty);
          /* Error Handling */
          if ( tcgetattr ( m_fd, &tty ) != 0 )
              throwError("tcgetattr");
          /* Save old tty parameters */
          tty_old = tty;
          /* Set Baud Rate */
          cfsetospeed (&tty, (speed_t)TC_BAUDRATE);
          cfsetispeed (&tty, (speed_t)TC_BAUDRATE);

          /* Setting other Port Stuff */
          tty.c_cflag     &=  ~PARENB;
          // Make 8n1
          tty.c_cflag     &=  ~CSTOPB;
          tty.c_cflag     &=  ~CSIZE;
          tty.c_cflag     |=  CS8;
          tty.c_cflag     &=  ~CRTSCTS;
          // no flow control
          tty.c_cc[VMIN]      =   1;
          // read doesn't block
          tty.c_cc[VTIME]     =   5;
          // 0.5 seconds read timeout
          tty.c_cflag     |=  CREAD | CLOCAL;
          // turn on READ & ignore ctrl lines

          /* Make raw */
          cfmakeraw(&tty);

          /* Flush Port, then applies attributes */
          tcflush( m_fd, TCIFLUSH );
          
          if ( tcsetattr ( m_fd, TCSANOW, &tty ) != 0)
              throwError("tcsetattr");
        }

  template<typename T>
  void print( const T& t)
        {
          std::ostringstream oss;
          oss << t;
          int len = oss.str().size();
          const char* data = oss.str().c_str();
          int n_written = 0;
          do 
          {
            int ret = write( m_fd, &data[n_written], len-n_written);
            if( ret < 0)
                throwError("write");
#ifdef SERIAL_DEBUG
            std::cout << "\e[31m" << "W:";
            for( int i = 0; i < ret; ++i)
            {
              std::cout << " 0x" << std::hex << int(data[n_written+i]) << std::dec;
            }
            std::cout << "\e[0m" << std::endl;
#endif
            n_written += ret;
          }
          while( n_written < len);
        }

  void print( uint8_t t)
        {
          print(int(t));
        }
  
  template<typename T>
  void println( const T& s)
        {
          print(s);
          print("\r\n");
          flush();
        }
  
  void flush()
        {
          tcflush( m_fd, TCIFLUSH);
        }
  
  int available()
        {
          fd_set rfds;
          FD_ZERO(&rfds);
          FD_SET(m_fd, &rfds);
          
          int retval = 0;
          struct timeval tv;
          tv.tv_sec = 0;
          //tv.tv_usec = 500*1000;
          tv.tv_usec = 0;
            retval = select(m_fd+1, &rfds, NULL, NULL, &tv);
            if (retval == -1)
            {
              if( errno == EINTR)
                  return 0;
              else
                  throwError("select");
            }
            
            if (retval > 0)
            {
              m_valid = 0;
              raw_read();
#ifdef SERIAL_DEBUG
              std:: cout << "\e[32m" << "R :";
              for( size_t i=0; i < m_valid; ++i)
                  std::cout <<" 0x" << std::hex << int(m_buffer[i]) << std::dec;
              std::cout << "\e[0m" << std::endl;
#endif
              return m_valid;
            }
                    
          return 0;
        }
  
  int readBytes( char* buf, size_t len)
        {
#ifdef SERIAL_DEBUG
          printf("Reading %d bytes (max: %d)\n", len, m_valid);
#endif
          int ret = len < m_valid ? len : m_valid;
          memcpy( buf, m_buffer, ret);
          return ret;
        }
private:
  void raw_read()
        {
          if( m_valid > BUFSIZE)
          {
#ifdef SERIAL_DEBUG
            std::cout << "Read buffer overflow" << std::endl;
#endif
            m_valid = 0;
          }
          int n = read( m_fd, m_buffer+m_valid, BUFSIZE-m_valid );
#ifdef SERIAL_DEBUG
          printf("Read %d bytes (max: %d)\n", n, BUFSIZE-m_valid);
#endif
          if( n < 0)
              m_valid = 0;
          else
              m_valid += n;
        }
  
  int    m_fd;
  char   m_buffer[BUFSIZE];
  size_t m_valid;
};

#endif
