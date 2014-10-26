#!/bin/bash

# only seems to work if the device is read from e.g.
# with minicom -b 9600 -D DEVICENAME
sleep_color=0.02
sleep_unicolor=0.004

device_linux=/dev/ttyUSB0
device_mac=/dev/tty.usbserial-A4006Fho
device_rpi=/dev/ttyAMA0

if [ -e $device_linux ]; then
    device=$device_linux
elif [ -e $device_mac ]; then
    device=$device_mac
elif [ -e $device_rpi ]; then
    device=$device_rpi
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
    echo -en "\x42\x01\x0\x5\xF\xF\xF\xF\xF\xF\xF\xF\xF\xF\xF\xF\xF\xF\xF" > $device
    sleep $sleep_color
    echo -en "\x42\x01\x0\\x5\x0\x0\x0\x0\x0\x0\x0\x0\x0\x0\x0\x0\x0\x0\x0" > $device
    sleep $sleep_color
}

echo "Resetting serial port"
# difference between startup on linux and after use of pyserial
#STTYOPTS="-echo -icrnl -ixon -opost -isig -icanon -iexten -echo -echoe -echok -echoctl -echoke"
# options found on Arduino forum
STTYOPTS="cs8 ignbrk -brkint -icrnl -imaxbel -opost -onlcr -isig -icanon -iexten -echo -echoe -echok -echoctl -echoke noflsh -ixon -crtscts"
stty -F $device sane
stty -F $device 115200 $STTYOPTS

echo "Starting tail"
tail -f $device &
TAIL_PID=$!
trap "echo -en '\x42\x69' > $device; kill $TAIL_PID; exit 0" SIGINT
#trap "echo -en '\x42\x69' > $device; exit 0" SIGINT

echo "Sending RESET"
echo -en "\x42\x69" > $device
sleep 1

echo "Updating colors"
#while true; do command_unicolor; done
while true; do command_color; done
