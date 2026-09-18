#!/bin/bash
# toggle-dashboard.sh
# Sends IPC to running Quickshell instance to toggle the dashboard.
# If Quickshell is not running, start it first.

if quickshell list 2>/dev/null | grep -q "quickshell"; then
    quickshell ipc call toggleDashboard
else
    quickshell -d
fi
