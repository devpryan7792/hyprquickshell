#!/usr/bin/env bash
# theme-switcher.sh
# Sets wallpaper via awww, generates Material You colors via Matugen,
# and updates Hyprland, Quickshell, and Ghostty live.

WALL_DIR="$HOME/Pictures/wallpaper"
WALL_CACHE="$HOME/.cache/hyprdots-wallpaper"
SCHEME_CACHE="$HOME/.cache/hyprdots-theme-scheme"
mkdir -p "$(dirname "$WALL_CACHE")"

# If changing scheme on existing wallpaper: theme-switcher.sh --scheme <type>
if [[ "$1" == "--scheme" && -n "$2" ]]; then
    SCHEME="$2"
    echo "$SCHEME" > "$SCHEME_CACHE"
    WALL=$(cat "$WALL_CACHE" 2>/dev/null)
    if [[ -z "$WALL" || ! -f "$WALL" ]]; then
        WALL=$(find "$WALL_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | head -n 1)
    fi
    MATUGEN_BIN="$(command -v matugen 2>/dev/null || echo "$HOME/.local/bin/matugen")"
    if [[ -x "$MATUGEN_BIN" && -f "$WALL" ]]; then
        "$MATUGEN_BIN" image "$WALL" --type "$SCHEME" --source-color-index 0 -c "$HOME/.config/matugen/config.toml"
        quickshell ipc call theme reload >/dev/null 2>&1 || true
        hyprctl reload &
    fi
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

SCHEME="scheme-tonal-spot"
if [[ -f "$SCHEME_CACHE" ]]; then
    CACHED_SCHEME=$(cat "$SCHEME_CACHE")
    if [[ -n "$CACHED_SCHEME" ]]; then
        SCHEME="$CACHED_SCHEME"
    fi
fi

# Generate dynamic color palettes first
MATUGEN_BIN="$(command -v matugen 2>/dev/null || echo "$HOME/.local/bin/matugen")"
if [[ -x "$MATUGEN_BIN" ]]; then
    "$MATUGEN_BIN" image "$WALL" --type "$SCHEME" --source-color-index 0 -c "$HOME/.config/matugen/config.toml"
    quickshell ipc call theme reload >/dev/null 2>&1 || true
fi

# Display wallpaper with smooth wipe transition asynchronously
awww img "$WALL" --transition-type wipe --transition-step 90 --transition-fps 144 &

# Reload Hyprland to update border colors
hyprctl reload &

# Ensure Quickshell is running if it was closed
if ! quickshell list 2>/dev/null | grep -q "quickshell"; then
    quickshell -d
fi

echo "Theme updated to match: $(basename "$WALL") with $SCHEME"