#!/usr/bin/env bash
# launch-app.sh
# Safely launches applications detached from Quickshell and updates frecency

EXEC_CMD="$1"
APP_NAME="$2"

if [[ -z "$EXEC_CMD" ]]; then
    exit 0
fi

# Update frecency cache in python
if [[ -n "$APP_NAME" ]]; then
    python3 -c "
import json, os, sys
cache_file = os.path.expanduser('~/.cache/quickshell-launcher-frecency.json')
app_name = sys.argv[1]
try:
    data = {}
    if os.path.exists(cache_file):
        with open(cache_file, 'r') as f:
            data = json.load(f)
    data[app_name] = data.get(app_name, 0) + 1
    with open(cache_file, 'w') as f:
        json.dump(data, f)
except Exception:
    pass
" "$APP_NAME" &
fi

# Launch process fully detached to avoid EPIPE / terminal attachment issues
nohup sh -c "$EXEC_CMD" >/dev/null 2>&1 &
