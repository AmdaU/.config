#!/usr/bin/env bash
# Streaming dictation via whisper.cpp whisper-stream.
# Press once to start; words appear live as you speak.
# Press again to stop.
#
# Requires: whisper-stream (CUDA build), wtype

WHISPER_STREAM="$HOME/.local/bin/whisper-stream"
WHISPER_MODEL="$HOME/.local/share/whisper/models/ggml-medium.bin"
FILTER_SCRIPT="$HOME/.config/scripts/dictation/whisper-stream-filter.py"
LOG="$HOME/.local/share/dictation-results.log"

if pgrep -x whisper-stream > /dev/null; then
    pkill -x whisper-stream
    notify-send -i microphone-sensitivity-muted "Dictation" "Stopped"
else
    notify-send -i microphone-sensitivity-high "Dictation" "Listening..." -t 60000

    "$WHISPER_STREAM" \
        --model  "$WHISPER_MODEL" \
        --step   1000 \
        --length 6000 \
        --keep   200 \
        --language en \
        2>/dev/null \
    | python3 -u "$FILTER_SCRIPT" \
    | while IFS= read -r chunk; do
        [ -n "$chunk" ] || continue
        echo "[$(date +%T)] $chunk" >> "$LOG"
        printf '%s ' "$chunk" | wtype -d 40 -
    done &
fi
