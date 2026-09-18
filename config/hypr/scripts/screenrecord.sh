#!/usr/bin/env bash
# screenrecord.sh
# Toggles region screen recording using wf-recorder

DIR="$HOME/Videos/recordings"
mkdir -p "$DIR"

if pgrep -x "wf-recorder" > /dev/null; then
    pkill -INT -x wf-recorder
    notify-send "Screen Recorder" "Recording stopped and saved to ~/Videos/recordings" -a "Recorder" 2>/dev/null || true
    exit 0
fi

if ! command -v wf-recorder &> /dev/null; then
    notify-send "Screen Recorder" "wf-recorder is not installed. Install via: sudo pacman -S wf-recorder" -u critical -a "Recorder" 2>/dev/null || true
    exit 1
fi

GEOMETRY=$(slurp)
if [[ -z "$GEOMETRY" ]]; then
    exit 0
fi

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
FILE="$DIR/recording_${TIMESTAMP}.mp4"

notify-send "Screen Recorder" "Recording started. Press SUPER+SHIFT+R to stop." -a "Recorder" 2>/dev/null || true
wf-recorder -g "$GEOMETRY" -f "$FILE"
