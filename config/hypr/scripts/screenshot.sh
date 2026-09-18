#!/usr/bin/env bash
# screenshot.sh
# Grim + Slurp screenshot tool with clipboard copy & notification

DIR="$HOME/Pictures/shots"
mkdir -p "$DIR"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
FILE="$DIR/screenshot_${TIMESTAMP}.png"

MODE="${1:-region}"

case "$MODE" in
    "full"|"output")
        grim "$FILE"
        ;;
    "window")
        GEOMETRY=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
        if [[ -z "$GEOMETRY" || "$GEOMETRY" == "null" ]]; then
            grim "$FILE"
        else
            grim -g "$GEOMETRY" "$FILE"
        fi
        ;;
    "region"|*)
        GEOMETRY=$(slurp)
        if [[ -z "$GEOMETRY" ]]; then
            # User pressed Escape or cancelled
            exit 0
        fi
        grim -g "$GEOMETRY" "$FILE"
        ;;
esac

if [[ -f "$FILE" ]]; then
    wl-copy < "$FILE"
    notify-send -i "$FILE" "Screenshot Captured" "Saved to ~/Pictures/shots/$(basename "$FILE")\nCopied to clipboard" -a "Screenshot" 2>/dev/null || true
fi
