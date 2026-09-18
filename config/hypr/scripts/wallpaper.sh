#!/bin/bash
# wallpaper.sh
# Restores last wallpaper on login/startup

WALL_CACHE="$HOME/.cache/hyprdots-wallpaper"
WALL_DIR="$HOME/Pictures/wallpaper"

if ! pgrep -x "awww-daemon" >/dev/null; then
    awww-daemon &
    sleep 0.5
fi

if [[ -f "$WALL_CACHE" ]]; then
    WALL=$(cat "$WALL_CACHE")
    if [[ -f "$WALL" ]]; then
        awww img "$WALL"
        exit 0
    fi
fi

# Fallback: pick any wallpaper from directory
WALL=$(find "$WALL_DIR" -maxdepth 1 -type f | head -n 1)
if [[ -n "$WALL" ]]; then
    awww img "$WALL"
    echo "$WALL" > "$WALL_CACHE"
fi
