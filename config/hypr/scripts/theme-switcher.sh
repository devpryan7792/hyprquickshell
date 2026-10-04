#!/usr/bin/env bash
# theme-switcher.sh
# Sets wallpaper via awww, generates dynamic colors via theme-engine.py,
# and updates Hyprland, Quickshell, and Ghostty live.

WALL_DIR="$HOME/Pictures/wallpaper"
WALL_CACHE="$HOME/.cache/hyprdots-wallpaper"
SCHEME_CACHE="$HOME/.cache/hyprdots-theme-scheme"
SURFACE_CACHE="$HOME/.cache/hyprdots-surface-mode"
ENGINE="$HOME/.config/hypr/scripts/theme-engine.py"

mkdir -p "$(dirname "$WALL_CACHE")"

# Load cached preferences
WALL=$(cat "$WALL_CACHE" 2>/dev/null)
SCHEME=$(cat "$SCHEME_CACHE" 2>/dev/null)
SURFACE_MODE=$(cat "$SURFACE_CACHE" 2>/dev/null)
[ -z "$SCHEME" ] && SCHEME="scheme-vibrant"
[ -z "$SURFACE_MODE" ] && SURFACE_MODE="obsidian"

# Handler for surface style change (--surface <obsidian|material>)
if [[ "$1" == "--surface" && -n "$2" ]]; then
    SURFACE_MODE="$2"
    echo "$SURFACE_MODE" > "$SURFACE_CACHE"
    if [[ -z "$WALL" || ! -f "$WALL" ]]; then
        WALL=$(find "$WALL_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | head -n 1)
    fi
    python3 "$ENGINE" "$WALL" "$SCHEME" "$SURFACE_MODE"
    quickshell ipc call theme reload >/dev/null 2>&1 || true
    hyprctl reload &
    touch "$HOME/.config/ghostty/config" 2>/dev/null || true
    exit 0
fi

# Handler for scheme change (--scheme <type>)
if [[ "$1" == "--scheme" && -n "$2" ]]; then
    SCHEME="$2"
    echo "$SCHEME" > "$SCHEME_CACHE"
    if [[ -z "$WALL" || ! -f "$WALL" ]]; then
        WALL=$(find "$WALL_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | head -n 1)
    fi
    python3 "$ENGINE" "$WALL" "$SCHEME" "$SURFACE_MODE"
    quickshell ipc call theme reload >/dev/null 2>&1 || true
    hyprctl reload &
    touch "$HOME/.config/ghostty/config" 2>/dev/null || true
    exit 0
fi

# Ensure awww-daemon is running
if ! pgrep -x "awww-daemon" >/dev/null; then
    awww-daemon &
    sleep 0.5
fi

# Determine wallpaper: use argument $1 if provided, otherwise pick randomly
if [[ -n "$1" && -f "$1" ]]; then
    WALL="$1"
else
    WALL=$(find "$WALL_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | shuf -n 1)
fi

if [[ -z "$WALL" || ! -f "$WALL" ]]; then
    echo "No wallpaper found in $WALL_DIR"
    exit 1
fi

echo "Setting wallpaper: $WALL"
echo "$WALL" > "$WALL_CACHE"

# Run unified Theme Engine
python3 "$ENGINE" "$WALL" "$SCHEME" "$SURFACE_MODE"

# Display wallpaper with smooth wipe transition asynchronously
awww img "$WALL" --transition-type wipe --transition-step 90 --transition-fps 144 &

# Reload components
quickshell ipc call theme reload >/dev/null 2>&1 || true
hyprctl reload &
touch "$HOME/.config/ghostty/config" 2>/dev/null || true

# Ensure Quickshell is running if it was closed
if ! quickshell list 2>/dev/null | grep -q "quickshell"; then
    quickshell -d
fi

echo "Theme updated to match: $(basename "$WALL") [$SURFACE_MODE / $SCHEME]"
