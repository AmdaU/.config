#!/bin/bash
stty -echo &&
echo "Press 'F2' to take the screenshot"
flameshot config -f $2
while sudo evtest /dev/input/event3 --query EV_KEY KEY_F2; do : ;
done
flameshot gui -p $1
echo "$1/$2.png"
while ! [ -f "$1/$2.png" ]; do
	sleep 1
done
flameshot config -f ""

