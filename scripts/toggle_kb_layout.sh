#!/usr/bin/env bash
# Cycle US ↔ Canadian French (matches input: kb_layout = us,ca and kb_variant = ,fr).
# Uses switchxkblayout so both layouts stay in the group list.

hyprctl switchxkblayout all next
