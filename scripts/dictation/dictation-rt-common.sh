# Shared helpers for dictation-rt-toggle.sh and dictation-rt-stop.sh
# shellcheck shell=bash

# Full paths so dunst/mako show an image. Prefer Breeze-Dark status icons (light strokes
# on transparent background) over Adwaita symbolic (dark monochrome) for dark notification UIs.
dictation_rt_resolve_icon() {
    local var="$1"
    shift
    local user="${!var-}"
    if [ -n "$user" ] && [ -f "$user" ]; then
        printf '%s\n' "$user"
        return 0
    fi
    local p
    for p in "$@"; do
        if [ -f "$p" ]; then
            printf '%s\n' "$p"
            return 0
        fi
    done
    printf '\n'
}

DICTATION_ICON_ON="$(dictation_rt_resolve_icon DICTATION_ICON_ON \
    /usr/share/icons/breeze-dark/status/24/microphone-sensitivity-high.svg \
    /usr/share/icons/breeze/status/24/microphone-sensitivity-high.svg \
    /usr/share/icons/Adwaita/symbolic/status/microphone-sensitivity-high-symbolic.svg)"
DICTATION_ICON_OFF="$(dictation_rt_resolve_icon DICTATION_ICON_OFF \
    /usr/share/icons/breeze-dark/status/24/microphone-sensitivity-muted.svg \
    /usr/share/icons/breeze/status/24/microphone-sensitivity-muted.svg \
    /usr/share/icons/Adwaita/symbolic/status/microphone-sensitivity-muted-symbolic.svg)"

dictation_rt_notify() {
    local icon="$1"
    shift
    if [ -f "$icon" ]; then
        notify-send -i "$icon" "$@"
    else
        notify-send "$@"
    fi
}

dictation_rt_stop() {
    # Ironbar + notify + pid file BEFORE pkill: voice stop runs this from a child of the
    # daemon; killing the daemon first would tear down that shell before UI cleanup runs.
    ironbar style remove-class dictation-mic listening 2>/dev/null || true
    dictation_rt_notify "$DICTATION_ICON_OFF" "Dictation (RT)" "Stopped"
    rm -f "$HOME/.local/share/dictation-rt.pid"
    pkill -f "realtimestt-daemon.py" 2>/dev/null || true
    pkill -f "dictation-venv.*python" 2>/dev/null || true
}
