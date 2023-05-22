# setWinIcon.sh
#!/bin/sh

# Usage: setWinIcon [title] [icon]
# - title: a string to match within the title of the window
# - icon: path to the icon file. Use png for best results.

title="$1"
ICONPATH="$2"

known_windows=$(wmctrl -l |grep $title|awk '{ print $1 }')

for id in ${known_windows}
do
    xseticon -id "$id" "$ICONPATH"
done
