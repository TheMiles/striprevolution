Serial communication
====================

By default, most boards will reset once a serial connection is
established.  Thus purely writing to the serial device will not work.
Two solutions exist for this issue:

- open a permanent connection with minicom or cat, e.g.
   minicom -b 9600 -D /dev/ttyUSB0
or
   cat /dev/ttyUSB0

- disable the automatic reset via hardware

Disabling automatic reset on serial connect
-----------------------------------------

The reset pin has to be connected to a 5V pin via a ~120 Ohm resistor
on most boards (except Arduino Uno which needs a 10uF cap between RST
and GND). Resistor method tested with EMS Diavolino and Boarduino.
