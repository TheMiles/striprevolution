#!/bin/bash

# only seems to work if the device is read from e.g.
# with minicom -b 9600 -D DEVICENAME
sleep_color=0.02
sleep_unicolor=0.004

device_linux=/dev/ttyUSB0
device_mac=/dev/tty.usbserial-A4006Fho

if [ -e $device_linux ]; then
    device=$device_linux
elif [ -e $device_mac ]; then
    device=$device_mac
else
    echo "Could not find usable device, exiting."
    exit 1
fi

echo "Using device '$device'"

# works well up to SLEEP=0.004
command_unicolor() {
    echo -en "\x42\x02\xF\xF\xF" > $device
    sleep $sleep_unicolor
    echo -en "\x42\x02\x00\x00\x00" > $device
    sleep $sleep_unicolor
}

# works well up to SLEEP=0.02
command_color() {
    echo -en "\x42\x01\x5\xF\xF\xF\xF\xF\xF\xF\xF\xF\xF\xF\xF\xF\xF\xF" > $device
    sleep $sleep_color
    echo -en "\x42\x01\x5\x0\x0\x0\x0\x0\x0\x0\x0\x0\x0\x0\x0\x0\x0\x0" > $device
    sleep $sleep_color
}

#echo -en "\x42\x68" > $device
#while true; do command_unicolor; done
while true; do command_color; done
