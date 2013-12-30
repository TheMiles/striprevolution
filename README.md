===============
striprevolution
===============

Running a strip of WS2811 based LEDs.

Can be controled via serial port. 

Usage
-----

To get debug output from the arduino you can use minicom:
		
		minicom -b 9600 -D /dev/ttyUSB0

First led to dark red

		echo -en "\x42\x01\x01\x0F\x00\x00" > /dev/ttyUSB0

Five leds to white

		echo -en "\x42\x01\x05\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF" > /dev/ttyUSB0

Toggle debug output
		
		echo -en "\x42\x4" > /dev/ttyUSB0


Commands
--------

Each command block has to start showing a magic number 66 in the first byte.

The second byte shows the command

Command           | code |    data length    |        description
------------------|------|-------------------|-------------------------------
 `NOOP`           |    0 |                 0 | no op
 `COLOR_VALUES`   |    1 |   see description | Set a number of leds. The *first byte* contains the **number** of remaining rgb values. Following is `number * 3` bytes in RGB order.
 `UNICOLOR`       |    2 |                 3 | Sets given color on all elements of the strip. The following three bytes contain the color in RGB order.
 `SINGLE_COLOR`   |    5 |                 3 | Sets given color on all elements of the strip. The following three bytes contain the color in RGB order.
 `TEST`           |    3 |                 0 | 
 `TESTRAW`        |    4 |                 0 | 
 `DEBUG`          |    6 |                 0 | Toggles debug feedback output via serial port. [on/off]


