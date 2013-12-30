#!/bin/bash

SLEEP=0.02


#echo -en "\x42\x05" > /dev/ttyUSB0
while true; do
    #echo -en "\x42\x02\x5F\x00\x00" > /dev/ttyUSB0
    echo -en "\x42\x02\xFF\xFF\xFF" > /dev/ttyUSB0
    sleep $SLEEP
    echo -en "\x42\x02\x00\x00\x00" > /dev/ttyUSB0
    sleep $SLEEP
done
