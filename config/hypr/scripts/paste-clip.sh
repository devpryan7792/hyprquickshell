#!/usr/bin/env bash
# paste-clip.sh
# Decodes selected cliphist ID or raw line and copies to Wayland clipboard.
# Optionally auto-pasts into the focused app via wtype if installed.

if [[ -z "$1" ]]; then
    exit 0
fi

CLIPHIST_BIN="$HOME/.local/bin/cliphist"
if [[ ! -x "$CLIPHIST_BIN" ]]; then
    CLIPHIST_BIN="cliphist"
fi

ID=$(echo "$1" | awk '{print $1}')

if [[ -n "$ID" ]]; then
    "$CLIPHIST_BIN" decode "$ID" | wl-copy
    notify-send "Clipboard" "Copied to clipboard — paste with Ctrl+V or middle-click" -t 1500 -a "Clipboard" 2>/dev/null || true

    # Auto-paste into focused app if wtype is available
    if command -v wtype >/dev/null 2>&1; then
        "$CLIPHIST_BIN" decode "$ID" | wtype -
    fi
fi
