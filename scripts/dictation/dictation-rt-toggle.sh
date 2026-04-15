#!/usr/bin/env bash
# RealtimeSTT dictation toggle (parallel to dictation-toggle.sh).
# Uses Silero VAD + faster-whisper instead of whisper-stream.
# Press once to start; press again to stop.
#
# Requires: dictation-venv with RealtimeSTT, wtype

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$HERE/dictation-rt-common.sh"

DAEMON="$HERE/realtimestt-daemon.py"
VENV_PYTHON="$HOME/.local/share/dictation-venv/bin/python3"
PID_FILE="$HOME/.local/share/dictation-rt.pid"
LOG="$HOME/.local/share/dictation-results.log"

_stop() {
    dictation_rt_stop
}

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    _stop
else
    # Clean up any orphaned processes from previous crashed sessions
    pkill -f "realtimestt-daemon.py" 2>/dev/null
    pkill -f "dictation-venv.*python" 2>/dev/null

    dictation_rt_notify "$DICTATION_ICON_ON" "Dictation (RT)" "Listening (loading model)..." -t 60000
    "$VENV_PYTHON" -u "$DAEMON" >> "$LOG" 2>&1 &
    echo $! > "$PID_FILE"
    ironbar style add-class dictation-mic listening 2>/dev/null
fi
