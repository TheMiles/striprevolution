#ifndef SERIALSELECTOR_H
#define SERIALSELECTOR_H

#ifdef HAVE_AVR // Arduino HardwareSerial
#define STRIP_PIN  6
#include <HardwareSerial.h>
typedef HardwareSerial LEDSerial;

#elif defined(HAVE_TEENSY3) // Teensyduino usb serial
#define STRIP_PIN  2
#include <usb_serial.h>
typedef usb_serial_class LEDSerial;

#elif defined(XBEE) // XBee serial
#include "XBeeSerial.h"
XBeeSerial Serial;
typedef XBeeSerial LEDSerial;
#endif

#endif
