#!/usr/bin/env bash
# caffeine.sh
# Manages idle inhibition for hypridle / systemd idle sleep

CACHE_FILE="$HOME/.cache/hyprdots-caffeine"
PID_FILE="$HOME/.cache/hyprdots-caffeine.pid"

mkdir -p "$(dirname "$CACHE_FILE")"

get_state() {
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null; then
        echo "on"
    else
        echo "off"
    fi
}

enable_caffeine() {
    # Kill any stale inhibitor
    pkill -f "who=hyprdots-caffeine" 2>/dev/null || true
    
    # Inhibit idle via systemd
    systemd-inhibit --what=idle --who="hyprdots-caffeine" --why="Caffeine mode active" sleep infinity &
    echo $! > "$PID_FILE"
    echo "on" > "$CACHE_FILE"
    
    # Pause hypridle timer if running
    killall -STOP hypridle 2>/dev/null || true
    
    notify-send "Caffeine Enabled" "Screen sleep and idle locking are disabled" -i preferences-desktop-screensaver -a "Caffeine" 2>/dev/null || true
}

disable_caffeine() {
    if [[ -f "$PID_FILE" ]]; then
        kill "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null || true
        rm -f "$PID_FILE"
    fi
    pkill -f "who=hyprdots-caffeine" 2>/dev/null || true
    echo "off" > "$CACHE_FILE"
    
    # Resume hypridle timer
    killall -CONT hypridle 2>/dev/null || true
    
    notify-send "Caffeine Disabled" "Normal screen timeout and sleep restored" -i preferences-desktop-screensaver -a "Caffeine" 2>/dev/null || true
}

case "$1" in
    "status")
        STATE=$(get_state)
        echo "{\"state\": \"$STATE\"}"
        ;;
    "toggle")
        CURRENT=$(get_state)
        if [[ "$CURRENT" == "on" ]]; then
            disable_caffeine
            echo "{\"state\": \"off\"}"
        else
            enable_caffeine
            echo "{\"state\": \"on\"}"
        fi
        ;;
    "on")
        enable_caffeine
        echo "{\"state\": \"on\"}"
        ;;
    "off")
        disable_caffeine
        echo "{\"state\": \"off\"}"
        ;;
    *)
        get_state
        ;;
esac
