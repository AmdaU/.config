#!/bin/bash
# Toggle "float next window" mode.
# Press once to arm — the next window that opens will be floated and centered.
# Press again to disarm. Auto-disarms after 10 seconds.

PIDFILE="/tmp/hypr_float_next.pid"
SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    kill "$(cat "$PIDFILE")" 2>/dev/null
    rm -f "$PIDFILE"
    notify-send -t 1500 "Float disarmed"
    exit 0
fi

echo $$ > "$PIDFILE"
trap 'rm -f "$PIDFILE"' EXIT

(sleep 10 && kill $$ 2>/dev/null) &

notify-send -t 2000 "Float armed" "Next window will spawn floating"

while IFS= read -r line; do
    if [[ "$line" == openwindow* ]]; then
        addr="${line#openwindow>>}"
        addr="${addr%%,*}"
        hyprctl --batch "dispatch togglefloating address:0x${addr};dispatch centerwindow"
        exit 0
    fi
done < <(socat -u "UNIX-CONNECT:$SOCKET" -)
