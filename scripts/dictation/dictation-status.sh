#!/bin/sh
pid_file="/home/amda/.local/share/dictation-rt.pid"
[ -f "$pid_file" ] && kill -0 "$(cat "$pid_file")" 2>/dev/null
