#!/usr/bin/env bash
# scratchpad-term.sh — Seamless Floating Scratchpad Terminal for Hyprland

# 1. If currently visible on focused monitor -> toggle off
current_special=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | .specialWorkspace.name // empty' 2>/dev/null)

if [ "$current_special" = "special:scratchpad" ]; then
    hyprctl dispatch 'hl.dsp.workspace.toggle_special("scratchpad")' >/dev/null 2>&1
    exit 0
fi

# 2. Currently hidden: check if client exists
if ! hyprctl clients -j 2>/dev/null | jq -e '.[] | select(.initialTitle == "Scratchpad")' >/dev/null 2>&1; then
    # Cold start: launch detached in user session
    systemd-run --user ghostty --gtk-single-instance=false --title="Scratchpad" >/dev/null 2>&1

    # Wait until Hyprland registers the window
    for _ in {1..30}; do
        current_special=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | .specialWorkspace.name // empty' 2>/dev/null)
        if [ "$current_special" = "special:scratchpad" ]; then
            break
        fi
        sleep 0.05
    done
fi

# 3. If still not visible, toggle it into view
current_special=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | .specialWorkspace.name // empty' 2>/dev/null)
if [ "$current_special" != "special:scratchpad" ]; then
    hyprctl dispatch 'hl.dsp.workspace.toggle_special("scratchpad")' >/dev/null 2>&1
fi
