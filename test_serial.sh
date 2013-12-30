#!/bin/bash

SLEEP=0.02
SERIAL_DEVICE=/dev/ttyUSB0


#echo -en "\x42\x05" > $SERIAL_DEVICE
while true; do
    #echo -en "\x42\x02\x5F\x00\x00" > $SERIAL_DEVICE
    echo -en "\x42\x02\xFF\xFF\xFF" > $SERIAL_DEVICE
    sleep $SLEEP
    echo -en "\x42\x02\x00\x00\x00" > $SERIAL_DEVICE
    sleep $SLEEP
done
