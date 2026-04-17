#!/usr/bin/env bash
# Stop RealtimeSTT dictation (same as the keybind's second press).
# Used by dictation-rt-toggle.sh and by voice command from realtimestt-daemon.py.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$HERE/dictation-rt-common.sh"
dictation_rt_stop
