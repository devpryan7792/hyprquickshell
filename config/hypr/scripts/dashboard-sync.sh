#!/usr/bin/env bash
# dashboard-sync.sh
# Fast aggregated telemetry and hardware states for Quickshell Dashboard

VOL_RAW=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
VOL=$(echo "$VOL_RAW" | awk '{print int($2 * 100)}')
[ -z "$VOL" ] && VOL=50
MUTED="false"
if echo "$VOL_RAW" | grep -q "\[MUTED\]"; then
    MUTED="true"
fi

MAX_B=$(brightnessctl m 2>/dev/null || echo 1)
CUR_B=$(brightnessctl g 2>/dev/null || echo 0)
BRI=$(( CUR_B * 100 / (MAX_B > 0 ? MAX_B : 1) ))

WIFI_RADIO=$(nmcli radio wifi 2>/dev/null || echo "disabled")
WIFI_SSID=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep "^yes:" | cut -d: -f2- | head -n 1)

CAFF_STATE="off"
if [[ -f "$HOME/.cache/hyprdots-caffeine.pid" ]] && kill -0 "$(cat "$HOME/.cache/hyprdots-caffeine.pid" 2>/dev/null)" 2>/dev/null; then
    CAFF_STATE="on"
fi

NL_STATE="off"
if [[ -f "$HOME/.cache/hyprdots-bluelight" ]]; then
    NL_STATE=$(cat "$HOME/.cache/hyprdots-bluelight" 2>/dev/null)
fi
[ -z "$NL_STATE" ] && NL_STATE="off"

SURF=$(cat "$HOME/.cache/hyprdots-surface-mode" 2>/dev/null || echo "obsidian")
SCHEME=$(cat "$HOME/.cache/hyprdots-theme-scheme" 2>/dev/null || echo "scheme-vibrant")
[ -z "$SURF" ] && SURF="obsidian"
[ -z "$SCHEME" ] && SCHEME="scheme-vibrant"

GM_STATE="off"
if [[ -f "$HOME/.cache/hyprdots-gamemode" ]] && [[ "$(cat "$HOME/.cache/hyprdots-gamemode" 2>/dev/null)" == "1" ]]; then
    GM_STATE="on"
fi

UPTIME=$(uptime -p 2>/dev/null | sed -e 's/up //' -e 's/ hours\?,/h/' -e 's/ minutes\?/m/' -e 's/ days\?,/d/' || echo "online")

echo "{\"vol\":$VOL,\"muted\":$MUTED,\"bri\":$BRI,\"wifi_radio\":\"$WIFI_RADIO\",\"wifi_ssid\":\"$WIFI_SSID\",\"caffeine\":\"$CAFF_STATE\",\"nightlight\":\"$NL_STATE\",\"gamemode\":\"$GM_STATE\",\"surface_mode\":\"$SURF\",\"scheme\":\"$SCHEME\",\"uptime\":\"$UPTIME\"}"
