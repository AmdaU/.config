#!/usr/bin/env bash
# Toggle between US and French Canadian (ca fr)

# For global input (not per-device)
current_layout=$(hyprctl -j getoption input:kb_layout 2>/dev/null | jq -r '.str' 2>/dev/null)

echo $current_layout

if [[ "$current_layout" == "us" ]]; then
  hyprctl keyword input:kb_layout "ca"
  hyprctl keyword input:kb_variant "fr"
else
  hyprctl keyword input:kb_layout "us"
  hyprctl keyword input:kb_variant "us"
  hyprctl reload
fi
