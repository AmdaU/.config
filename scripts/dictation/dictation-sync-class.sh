#!/bin/sh
# Polled by ironbar show_if to keep the dictation widget's CSS class
# in sync with daemon state. Always exits 0 so the widget stays visible.
pid_file="/home/amda/.local/share/dictation-rt.pid"
if [ -f "$pid_file" ] && kill -0 "$(cat "$pid_file")" 2>/dev/null; then
    ironbar style add-class dictation-mic listening 2>/dev/null
else
    ironbar style remove-class dictation-mic listening 2>/dev/null
fi
exit 0
