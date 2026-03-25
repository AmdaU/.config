#!/bin/bash

# Start WiVRn if not already running
if ss -lnt | awk '{print $4}' | grep -qE '(:|\.)9757$'; then
  echo "WiVRn server already listening on 9757"
else
  echo "Starting WiVRn server..."
  wivrn-server &
  sleep 5
fi


# start app on headset and connect
adb reverse tcp:9757 tcp:9757                                                               
adb shell am start -a android.intent.action.VIEW -d "wivrn+tcp://localhost" org.meumeu.wivrn

# set audio output to wivrn :)
sleep 2
pactl set-default-sink wivrn.sink 
