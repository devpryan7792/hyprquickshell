#!/usr/bin/env bash
# toggle-wallpaper.sh — Reliable Quickshell Wallpaper Picker toggle
if ! quickshell list 2>/dev/null | grep -q "quickshell"; then
    quickshell -d &
    sleep 0.4
fi
quickshell ipc call wallpaper toggle >/dev/null 2>&1 || true
