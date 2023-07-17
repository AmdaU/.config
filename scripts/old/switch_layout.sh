#!/bin/bash

if [[ $(setxkbmap -print | awk -F"+" '/xkb_symbols/ {print $2}') = "us" ]]; then
	ibus engine xkb:ca::fra 
else
 	ibus engine xkb:us::eng
fi
