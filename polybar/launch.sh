#!/bin/bash

killall -q polybar

while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

polybar mainbar-bspwm &

if [[ $(xrandr -q | grep 'DP1 connected') ]]; then
	polybar 2nd &
fi
