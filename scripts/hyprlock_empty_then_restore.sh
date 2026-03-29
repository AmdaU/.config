#!/usr/bin/env bash
# Jump to an empty workspace so hyprlock's screenshot shows wallpaper (e.g. Wallpaper Engine),
# then return to the workspace you were on after unlock.

notify_lock_off() {
  dunstctl close-all 2>/dev/null || true
  dunstctl set-paused true 2>/dev/null || true
  makoctl dismiss --all 2>/dev/null || true
  makoctl mode -a locked 2>/dev/null || true
  swaync-client --close-all 2>/dev/null || true
  swaync-client --dnd-on 2>/dev/null || true
}

notify_lock_on() {
  swaync-client --dnd-off 2>/dev/null || true
  makoctl mode -r locked 2>/dev/null || true
  dunstctl set-paused false 2>/dev/null || true
}

prev=$(hyprctl activeworkspace -j | jq -r '.id')
prev_layout=$(hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .active_layout_index // 0' | head -1)
[[ -z "$prev_layout" ]] && prev_layout=0
mapfile -t pinned < <(hyprctl clients -j | jq -r '.[] | select(.pinned == true) | .address')
for addr in "${pinned[@]}"; do
  hyprctl dispatch pin "address:${addr}" || true
done
hyprctl dispatch workspace emptynm
# Let workspace fade / compositor paint one frame before the grab (tune if screenshot is mid-animation)
killall ironbar
sleep 0.25
hyprctl switchxkblayout all 0
notify_lock_off
hyprlock || true
notify_lock_on
hyprctl switchxkblayout all "$prev_layout"
ironbar & disown
hyprctl dispatch workspace "$prev"
for addr in "${pinned[@]}"; do
  hyprctl dispatch pin "address:${addr}" || true
done
