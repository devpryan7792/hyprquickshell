#!/usr/bin/env bash
# bluelight.sh
# Hyprland Blue-Light / Night Light filter manager using hyprsunset

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/bluelight_state"
HYPRSUNSET_BIN="$(command -v hyprsunset 2>/dev/null || echo "$HOME/.local/bin/hyprsunset")"

# Ensure hyprsunset daemon is running
ensure_daemon() {
    if ! pgrep -x "hyprsunset" >/dev/null; then
        if [[ -x "$HYPRSUNSET_BIN" ]]; then
            nohup "$HYPRSUNSET_BIN" -i >/dev/null 2>&1 &
            sleep 0.3
        fi
    fi
}

current=$(cat "$STATE_FILE" 2>/dev/null || echo "off")
ACTION="${1:-toggle}"

case "$ACTION" in
    "status")
        case "$current" in
            "3500")
                echo '{"state":"3500","label":"3500K","name":"Warm","active":true}'
                ;;
            "4500")
                echo '{"state":"4500","label":"4500K","name":"Mild","active":true}'
                ;;
            "2700")
                echo '{"state":"2700","label":"2700K","name":"Night","active":true}'
                ;;
            "off"|*)
                echo '{"state":"off","label":"Off","name":"Off","active":false}'
                ;;
        esac
        exit 0
        ;;

    "set")
        TARGET="${2:-off}"
        ensure_daemon
        case "$TARGET" in
            "3500")
                hyprctl hyprsunset temperature 3500 >/dev/null 2>&1
                next="3500"
                msg="Warm (3500K)"
                ;;
            "4500")
                hyprctl hyprsunset temperature 4500 >/dev/null 2>&1
                next="4500"
                msg="Mild (4500K)"
                ;;
            "2700")
                hyprctl hyprsunset temperature 2700 >/dev/null 2>&1
                next="2700"
                msg="Night (2700K)"
                ;;
            "off"|*)
                hyprctl hyprsunset identity >/dev/null 2>&1
                next="off"
                msg="Disabled (Daylight)"
                ;;
        esac
        echo "$next" > "$STATE_FILE"
        notify-send "Night Light" "$msg" -i "weather-clear-night" -a "Display" -t 1500 2>/dev/null || true
        ;;

    "toggle"|*)
        ensure_daemon
        case "$current" in
            "off")
                next="4500"
                hyprctl hyprsunset temperature 4500 >/dev/null 2>&1
                msg="Mild (4500K)"
                ;;
            "4500")
                next="3500"
                hyprctl hyprsunset temperature 3500 >/dev/null 2>&1
                msg="Warm (3500K)"
                ;;
            "3500")
                next="2700"
                hyprctl hyprsunset temperature 2700 >/dev/null 2>&1
                msg="Night (2700K)"
                ;;
            "2700"|*)
                next="off"
                hyprctl hyprsunset identity >/dev/null 2>&1
                msg="Disabled (Daylight)"
                ;;
        esac
        echo "$next" > "$STATE_FILE"
        notify-send "Night Light" "$msg" -i "weather-clear-night" -a "Display" -t 1500 2>/dev/null || true
        ;;
esac
