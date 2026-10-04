#!/usr/bin/env bash
# game-mode.sh
# Toggle zero-latency gaming / performance mode in Hyprland

CACHE="$HOME/.cache/hyprdots-gamemode"
mkdir -p "$(dirname "$CACHE")"

STATE=0
[[ -f "$CACHE" ]] && STATE=$(cat "$CACHE" 2>/dev/null || echo 0)

if [[ "$1" == "status" ]]; then
    echo "$STATE"
    exit 0
fi

if [[ "$1" == "on" || ( "$1" != "off" && "$STATE" -eq 0 ) ]]; then
    # Enable Game Mode: Drop all blur, shadows, animations to 0 for maximum FPS
    hyprctl eval "hl.config({ decoration = { blur = { enabled = false }, shadow = { enabled = false } }, animations = { enabled = false } })" >/dev/null 2>&1
    echo 1 > "$CACHE"
    notify-send -a "Hyprland Rice" -i "input-gaming" "Performance Mode: ON" "Disabled blur, shadows, and animations for maximum FPS." 2>/dev/null || true
else
    # Restore Normal Rice: Re-enable blur, shadows, animations
    hyprctl eval "hl.config({ decoration = { blur = { enabled = true }, shadow = { enabled = true } }, animations = { enabled = true } })" >/dev/null 2>&1
    echo 0 > "$CACHE"
    notify-send -a "Hyprland Rice" -i "preferences-desktop-display" "Performance Mode: OFF" "Restored blur, shadows, and smooth spring animations." 2>/dev/null || true
fi
