#!/usr/bin/env bash
set -euo pipefail

DEV="/dev/input/by-id/usb-Sony_Interactive_Entertainment_DualSense_Wireless_Controller-if03-event-joystick"

# Wait for the device to exist (handles replug)
while true; do
  if [ -e "$DEV" ]; then
    # Grab until the device disappears; then loop to re-grab on next plug-in
    evtest --grab "$DEV" >/dev/null 2>&1 || true
    # If evtest exits (device removed or permission denied), wait briefly
  fi
  sleep 0.5
done
