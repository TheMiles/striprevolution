Serial communication
====================

By default, most boards will reset once a serial connection is
established.  Thus purely writing to the serial device will not work.
Two solutions exist for this issue:

- open a permanent connection with minicom or tail, e.g.
   @minicom -b 9600 -D /dev/ttyUSB0@ or @tail -f /dev/ttyUSB0@

- disable the automatic reset via hardware

Disabling automatic reset on serial connect
-----------------------------------------

The reset pin has to be connected to a 5V pin via a ~120 Ohm resistor
on most boards (except Arduino Uno which needs a 10uF cap between RST
and GND). The resistor method was tested with EMS Diavolino.  This
method does not work for the Boarduino. Supposedly the auto-reset cap
C6 has to be removed in order to achieve the same goal but this has
not been tested.

Baud rate
---------

Optimum (fastest possible) transfer rate for a 16 MHz chip seems to be
76800. This is not supported by terminal emulators such as minicom or
picocom but seems to work e.g. in python.
