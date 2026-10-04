#!/usr/bin/env bash
# toggle-dropdown-terminal.sh
# Quake-style dropdown terminal toggle for Hyprland

# Check if dropdown terminal is already running
if ! hyprctl -j clients 2>/dev/null | grep -q '"initialTitle": "dropdown-terminal"'; then
    # Launch ghostty with title dropdown-terminal via Hyprland session
    hyprctl dispatch 'hl.dsp.exec_cmd("ghostty --title=dropdown-terminal")' >/dev/null 2>&1
    sleep 0.25
fi

# Toggle special workspace 'dropdown'
hyprctl eval "hl.dsp.workspace.toggle_special('dropdown')" >/dev/null 2>&1 || true
