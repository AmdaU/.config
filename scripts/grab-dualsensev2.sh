#!/usr/bin/env bash
# Verbose DualSense grabber for USB and Bluetooth.
# Requires: evtest, udevadm; and sudoers NOPASSWD for /usr/bin/evtest

set -euo pipefail

LOG_TS_FMT='%F %T'

log() {
  # usage: log LEVEL MESSAGE...
  local lvl="$1"
  shift
  echo "[$lvl][grab-dualsense] $(date +"$LOG_TS_FMT") $*" >&2
}

dbg() { log DEBUG "$@"; }
inf() { log INFO "$@"; }
wrn() { log WARN "$@"; }

# Known Sony DualSense model IDs (extend if needed)
is_dualsense_vidpid() {
  local vid="${1,,}" pid="${2,,}"
  case "$vid:$pid" in
    054c:0ce6|054c:0df2|054c:0e6f) return 0 ;; # DS5 / DS5 Edge variants
    *) return 1 ;;
  esac
}

has_cap() {
  # usage: has_cap /dev/input/eventNN EV_KEY BTN_SOUTH
  evtest --query "$1" "$2" "$3" >/dev/null 2>&1
}

looks_like_gamepad() {
  local ev="$1"
  local ok=0
  if has_cap "$ev" EV_KEY BTN_SOUTH; then
    dbg "$ev: has BTN_SOUTH"
    ok=1
  else
    dbg "$ev: lacks BTN_SOUTH"
  fi
  if has_cap "$ev" EV_ABS ABS_X; then
    dbg "$ev: has ABS_X"
    ok=1
  else
    dbg "$ev: lacks ABS_X"
  fi
  [ $ok -eq 1 ]
}

is_candidate() {
  local ev="$1"
  dbg "Inspecting $ev"

  local props bus vid pid name
  props=$(udevadm info -q property -n "$ev" 2>/dev/null || true)
  if [ -z "$props" ]; then
    dbg "$ev: no udev props; skip"
    return 1
  fi

  bus=$(echo "$props" | sed -n 's/^ID_BUS=\(.*\)/\1/p')
  vid=$(echo "$props" | sed -n 's/^ID_VENDOR_ID=\(.*\)/\1/p')
  pid=$(echo "$props" | sed -n 's/^ID_MODEL_ID=\(.*\)/\1/p')
  name=$(echo "$props" | sed -n 's/^NAME="\([^"]*\)"/\1/p')
  [ -n "$name" ] || name="<unknown>"

  dbg "$ev props: BUS=${bus:-?} VID=${vid:-?} PID=${pid:-?} NAME=\"$name\""

  # Must look like a gamepad by capabilities
  if ! looks_like_gamepad "$ev"; then
    dbg "$ev: not gamepad by caps; skip"
    return 1
  fi

  # If VID/PID present, only accept Sony DualSense to avoid grabbing other pads
  if [ -n "${vid:-}" ] && [ -n "${pid:-}" ]; then
    if is_dualsense_vidpid "$vid" "$pid"; then
      dbg "$ev: Sony DualSense VID:PID; accept"
      return 0
    else
      dbg "$ev: not Sony DualSense; skip"
      return 1
    fi
  fi

  # No VID/PID (common over Bluetooth on your system) — accept by caps
  dbg "$ev: no VID/PID; accept by caps"
  return 0
}

already_grabbed() {
  local ev="$1"
  if pgrep -af "[e]vtest --grab $ev" >/dev/null 2>&1; then
    dbg "$ev: already grabbed"
    return 0
  fi
  return 1
}

grab_loop_one() {
  local ev="$1"
  inf "Grabbing $ev"
  while [ -e "$ev" ]; do
    if ! sudo -n evtest --grab "$ev" >/dev/null 2>&1; then
      wrn "$ev: evtest --grab failed (add NOPASSWD for /usr/bin/evtest?)"
      sleep 2
      continue
    fi
    dbg "$ev: evtest exited; will retry if device persists"
    sleep 0.2
  done
  dbg "$ev: device node vanished"
}

main() {
  inf "Starting DualSense grabber (very verbose)"
  while true; do
    for ev in /dev/input/event*; do
      [ -e "$ev" ] || continue
      if is_candidate "$ev"; then
        if ! already_grabbed "$ev"; then
          grab_loop_one "$ev" &
          disown || true
          sleep 0.05
        fi
      fi
    done
    sleep 1
  done
}

main
