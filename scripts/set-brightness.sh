#!/bin/bash
hour=$(date +%-H)

if [ "$hour" -ge 7 ] && [ "$hour" -lt 21 ]; then
    ddcutil setvcp 10 100
else
    ddcutil setvcp 10 0
fi
