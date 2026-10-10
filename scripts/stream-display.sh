#!/usr/bin/env bash
#
# stream-display.sh — park Steam Remote Play games on a headless Hyprland output.
#
# Why this exists: Steam's Remote Play host captures the X11 root cropped to the
# window it is currently tracking ("Desktop X11 RGB + libyuv + NVENC HEVC" in
# ~/.local/share/Steam/logs/streaming_log.txt), so the encoded stream resolution
# is literally the game window's on-screen size. Under a tiling layout that is
# whatever slab Hyprland assigned — 2546x678 for a half-tiled window — which the
# client then stretches over its whole screen. Steam's own "ChangeDesktopResolution"
# option is already enabled and cannot help: it drives Xwayland RandR, and
# Hyprland does not honour mode sets from Xwayland clients.
#
# A headless output at the client's negotiated resolution, with the game
# fullscreened on it, is the thing that checkbox was supposed to do.
#
# What this does NOT do: let you use the desktop while someone else streams.
# Steam re-points its capture at whatever window holds X focus and deliberately
# blanks the stream ("Capture method set to Desktop Black Frame") when that is
# not a tracked game window. That is Steam's privacy behaviour and no compositor
# arrangement overrides it — focus is global. True concurrent use needs a second
# session with its own Xwayland.
#
# Usage: stream-display.sh on|off|toggle|status|watch
#
#   watch  polls for the steam-streaming-playback PipeWire sink, which Steam
#          creates for the duration of a Remote Play session, and flips on/off
#          to match. Run it from a user service if you want this hands-off.
#
#          CAVEAT: the Quest 2 is also a registered Remote Play device, and it
#          creates the same sink. A VR session does not want to be forced onto a
#          flat 1080p output, so do not leave `watch` running unless flat-screen
#          streaming is the only Remote Play you do -- or teach it to check which
#          client connected first.
#
# Config via environment:
#   STREAM_DISPLAY_MODE      default 1920x1080@60  (match the client)
#   STREAM_DISPLAY_POSITION  default 3200x1800
#
# The default position is deliberately NOT edge-adjacent to HDMI-A-1 (0,0
# 2560x1440). A disjoint layout means the physical mouse cannot slide off an
# edge into a screen you cannot see, while Steam's absolute XTEST pointer warps
# still land on it correctly. If remote mouse input ever misbehaves, making the
# position adjacent (e.g. 2560x0) is the first thing to try.

set -euo pipefail

MODE="${STREAM_DISPLAY_MODE:-1920x1080@60}"
POSITION="${STREAM_DISPLAY_POSITION:-3200x1800}"
STATE="${XDG_RUNTIME_DIR:-/tmp}/stream-display.output"
WORKSPACE="name:stream"

die() { echo "stream-display: $*" >&2; exit 1; }
log() { echo "stream-display: $*"; }

# Hyprland 0.56 with a Lua config rejects `hyprctl keyword` outright
# ("keyword can't work with non-legacy parsers"), so every runtime change has to
# go through `hyprctl eval`. Note that eval prints "ok" rather than returning a
# value — read state back with `hyprctl -j monitors` instead.
hypr_eval() {
	hyprctl eval "$1" >/dev/null || die "eval failed: $1"
}

headless_outputs() {
	hyprctl -j monitors all | python3 -c '
import json, sys
for m in json.load(sys.stdin):
    if m.get("name", "").startswith("HEADLESS-"):
        print(m["name"])
'
}

output_exists() { headless_outputs | grep -qx -- "$1"; }

streaming_active() {
	pactl list short sinks 2>/dev/null | grep -q 'steam-streaming-playback'
}

current_output() {
	[[ -f $STATE ]] || return 1
	local out
	out=$(<"$STATE")
	[[ -n $out ]] && output_exists "$out" && printf '%s' "$out"
}

# Toggle the window rules declared in hyprland-local-desktop.lua. They are
# created disabled so that playing locally is unaffected; only a live stream
# should banish games to a screen you cannot see.
set_rules() {
	hypr_eval "for _, r in ipairs(_G.STREAM_RULES or {}) do r:set_enabled($1) end"
}

cmd_on() {
	local out before after
	out=$(current_output || true)

	if [[ -z $out ]]; then
		# The HEADLESS-N counter increments across create/remove cycles, so the
		# name is discovered by diffing rather than assumed to be HEADLESS-2.
		before=$(headless_outputs | sort)
		hyprctl output create headless >/dev/null || die "could not create headless output"
		for _ in $(seq 20); do
			after=$(headless_outputs | sort)
			out=$(comm -13 <(printf '%s\n' "$before") <(printf '%s\n' "$after") | head -1)
			[[ -n $out ]] && break
			sleep 0.1
		done
		[[ -n $out ]] || die "headless output never appeared"
		printf '%s' "$out" >"$STATE"
	fi

	# A headless output has no vblank; Hyprland paces it off the configured mode.
	# Leaving it at "preferred" is how you end up with a stream that looks like a
	# network problem, so the refresh rate is always stated explicitly.
	hypr_eval "hl.monitor{ output = '$out', mode = '$MODE', position = '$POSITION', scale = 1 }"
	hypr_eval "hl.workspace_rule{ workspace = '$WORKSPACE', monitor = '$out', default = true, persistent = true }"
	set_rules true

	# Window rules only fire when a window maps, so anything already running
	# predates them and has to be moved by hand.
	#
	# fullscreen_state rather than fullscreen: the latter is a *toggle*, so on an
	# already-fullscreen window it does exactly the wrong thing. Both `internal`
	# and `client` are required; client=2 is what makes the game itself render at
	# the output's 1920x1080 rather than letterboxing its old size into it.
	hypr_eval "
		for _, w in ipairs(hl.get_windows()) do
			if w.class and w.class:match('^steam_app_%d+\$') then
				pcall(function()
					hl.dispatch(hl.dsp.window.move{ window = 'address:' .. w.address, workspace = '$WORKSPACE' })
					hl.dispatch(hl.dsp.window.fullscreen_state{ window = 'address:' .. w.address, internal = 2, client = 2 })
					-- Steam only re-points its capture when focus changes, so a
					-- game sitting unfocused on the virtual output streams as a
					-- black frame. Focusing it is what actually starts the feed.
					hl.dispatch(hl.dsp.focus{ window = 'address:' .. w.address })
				end)
			end
		end
	"

	log "on: $out at $MODE ($POSITION), workspace $WORKSPACE"
}

cmd_off() {
	set_rules false

	# Order matters. Hyprland rehomes the *workspace* when an output goes away,
	# but a game fullscreened on that output loses its display underneath it and
	# unmaps itself -- the process stays alive while the window vanishes from
	# `hyprctl clients` entirely, and only comes back if the output returns.
	# So the windows have to be walked home first, while the output still exists.
	hypr_eval "
		for _, w in ipairs(hl.get_windows()) do
			if w.class and w.class:match('^steam_app_%d+\$') then
				pcall(function()
					hl.dispatch(hl.dsp.window.move{ window = 'address:' .. w.address, workspace = '1' })
				end)
			end
		end
	"
	sleep 0.3

	local out
	out=$(current_output || true)
	if [[ -n $out ]]; then
		hyprctl output remove "$out" >/dev/null || die "could not remove $out"
		log "off: removed $out"
	else
		log "off: no virtual output to remove"
	fi
	rm -f "$STATE"
}

# Called from the config.reloaded hook. Unlike `on` this never *creates* an
# output -- a reload should restore whatever was already running, not conjure a
# virtual screen because Hyprland happened to reload. The delay lets the
# catch-all `hl.monitor{ output = "" }` rule finish its auto-placement pass
# first, otherwise it re-positions the headless output right back on top of us.
cmd_reapply() {
	current_output >/dev/null 2>&1 || exit 0
	sleep 1
	cmd_on
}

cmd_status() {
	local out
	out=$(current_output || true)
	echo "virtual output : ${out:-none}"
	echo "mode           : $MODE"
	echo "streaming      : $(streaming_active && echo yes || echo no)"
	if [[ -n $out ]]; then
		hyprctl -j monitors | OUT="$out" python3 -c '
import json, os, sys
want = os.environ["OUT"]
for m in json.load(sys.stdin):
    if m["name"] == want:
        ws = m["activeWorkspace"]["name"]
        print("live           : {}x{}@{:.2f} at {},{} ws={}".format(
            m["width"], m["height"], m["refreshRate"], m["x"], m["y"], ws))
'
	fi
}

cmd_watch() {
	local active=no
	log "watching for Remote Play sessions (Ctrl-C to stop)"
	while :; do
		if streaming_active; then
			[[ $active == no ]] && { cmd_on; active=yes; }
		else
			[[ $active == yes ]] && { cmd_off; active=no; }
		fi
		sleep 3
	done
}

case "${1:-status}" in
on) cmd_on ;;
off) cmd_off ;;
reapply) cmd_reapply ;;
toggle) if current_output >/dev/null; then cmd_off; else cmd_on; fi ;;
status) cmd_status ;;
watch) cmd_watch ;;
*) die "usage: ${0##*/} on|off|toggle|status|watch" ;;
esac
