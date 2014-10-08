===============
striprevolution
===============

Running a strip of WS2811 based LEDs.

Can be controlled via serial port. 

Usage
-----

To get debug output from the arduino you can use minicom:
		
		minicom -b 115200 -D /dev/ttyUSB0

First led to dark red

		echo -en "\x42\x01\x01\x0F\x00\x00" > /dev/ttyUSB0

Five leds to white

		echo -en "\x42\x01\x05\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF" > /dev/ttyUSB0

Toggle debug output
		
		echo -en "\x42\x68" > /dev/ttyUSB0

All LEDs off
		
		echo -en "\x42\x69" > /dev/ttyUSB0


Commands
--------

Each command block has to start showing a magic number 66 (0x42) in the first byte.

The second byte shows the command

Command           | code |    data length    |        description
------------------|------|-------------------|-------------------------------
 `NOOP`           | 0x00 |                 0 | no op
 `COLOR`          | 0x01 |   see description | Set a number of leds. The *first byte* contains the **number** of remaining RGB values, followed by `number * 3` bytes in RGB order.
 `UNICOLOR`       | 0x02 |                 3 | Sets given color on all elements of the strip. The following three bytes contain the color in RGB order.
 `SINGLE_COLOR`   | 0x03 |                 3 | Sets given color on all elements of the strip. The following three bytes contain the color in RGB order.
 `BRIGHT`         | 0x04 |                 1 | Sets brightness to given value.
 `RAINBOW`        | 0x05 |                 0 | Sets all LEDs to a rainbow pattern.
 `STATE`          | 0x06 |                 0 | Prints nled*3 bytes containing the currently set color values of all leds.
 `TEST`           | 0x61 |                 0 | Runs a test pattern.
 `TESTRAW`        | 0x62 |                 0 | Runs another test pattern.
 `CONF`           | 0x67 |                 0 | Prints baudrate, number of leds and log level.
 `DEBUG`          | 0x68 |                 0 | Toggles debug feedback output via serial port.
 `RESET`          | 0x69 |                 0 | Sets all LEDs to black.
 `SETSIZE`        | 0x70 |                 1 | Resizes the current strip length. The new strip length is given by the single data byte (valid range: 0-255).
 `SPEEDTEST`      | 0x71 |                 0 | Returns the number '0' (for serial speed testing).
 `MEMFREE`        | 0x72 |                 0 | Returns the memory available in bytes.
