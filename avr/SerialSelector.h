#ifndef SERIALSELECTOR_H
#define SERIALSELECTOR_H

#if defined(XBEE) // XBee serial
#include "XBeeSerial.h"
typedef XBeeSerial LEDSerial;
#else // XBEE

#if defined (HAVE_AVR) // Arduino HardwareSerial
#include <HardwareSerial.h>
typedef HardwareSerial LEDSerial;
#elif defined(HAVE_TEENSY3) // Teensyduino usb serial
#include <usb_serial.h>
typedef usb_serial_class LEDSerial;
#endif // HAVE_TEENSY3

#endif // XBEE
#endif // SERIALSELECTOR_H
