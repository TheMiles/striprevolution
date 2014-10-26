General notes
=============

- Compiling without optimization (`-Os`) will break the LED timing
- Compiling with `-DSAVEMEM` (enabled by default) will remove all debug logging from the code but free another ~400 bytes of SRAM.

                  | program | data | Free SRAM | max LEDs
------------------|---------|------|-----------|----------
 w/  `-DSAVEMEM`  |    7790 |  454 |      1484 |      451
 w/o `-DSAVEMEM`  |   10062 |  850 |      1087 |      318

Serial communication
====================

By default, most boards will reset once a serial connection is
established.  Thus purely writing to the serial device will not work.
Two solutions exist for this issue:

- open a permanent connection with minicom or tail, e.g.
   @minicom -b 9600 -D /dev/ttyUSB0@ or @tail -f /dev/ttyUSB0@

- disable the automatic reset via hardware

When using the terminal to communicate with the serial device, make sure that the tty is set up properly (i.e. use stty).

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

Optimum transfer rate for a 16 MHz chip seems to be
76800. This is not supported by terminal emulators such as minicom or
picocom but seems to work e.g. in python. However, more recently also
115200 baud connections have proven to work reliably.

Serial over TCP
---------------

Communication with a serial device can be relayed over TCP using the
tools _ser2net_ and _socat_.

For example, with

    DEVNAME=/dev/ttyAMA0
    SERVER_IP=192.168.178.1
    SERVER_PORT=12345
   
on the server side (connected to the 'real' serial device), run:

    sudo ser2net -d -C "$SERVER_PORT:raw:0:$DEVNAME:115200 8DATABITS NONE 1STOPBIT"

On the client side, run:

    socat pty,link=$HOME/dev/vmodem0 tcp:$SERVER_IP:$SERVER_PORT
    
The device `$HOME/dev/vmodem0` can now be used by client programs.

Raspberry Pi serial usage
-------------------------

In order to use the onboard serial device of the RasPi `/dev/ttyAMA0`, it has to be released from being used for kernel logging first:

- remove `console=ttyAMA0,115200 kgdboc=ttyAMA0,115200` from `/boot/cmdline.txt`

- comment out `T0:23:respawn:/sbin/getty -L ttyAMA0 115200 vt100` in `/etc/inittab`

- reboot
