#!/bin/sh
# Polled by ironbar show_if to keep the dictation widget's CSS class
# in sync with daemon state. Always exits 0 so the widget stays visible.
#
# Use a short timeout on every IPC call so ironbar startup isn't delayed
# when the IPC socket isn't accepting connections yet.
ib() { timeout 0.3 ironbar "$@" 2>/dev/null || true; }

pid_file="/home/amda/.local/share/dictation-rt.pid"
if [ -f "$pid_file" ] && kill -0 "$(cat "$pid_file")" 2>/dev/null; then
    ib style add-class dictation-mic listening
else
    ib style remove-class dictation-mic listening
fi
verbatim_flag="/home/amda/.local/share/dictation-verbatim.flag"
if [ -f "$verbatim_flag" ]; then
    ib style add-class dictation-mic verbatim
else
    ib style remove-class dictation-mic verbatim
fi
command_flag="/home/amda/.local/share/dictation-command.flag"
if [ -f "$command_flag" ]; then
    ib style add-class dictation-mic command
else
    ib style remove-class dictation-mic command
fi
exit 0
