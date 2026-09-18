#!/usr/bin/env python3
import subprocess
import json
import sys
import os

def get_clipboard_history():
    cliphist_bin = os.path.expanduser("~/.local/bin/cliphist")
    if not os.path.exists(cliphist_bin):
        cliphist_bin = "cliphist"

    try:
        res = subprocess.run([cliphist_bin, "list"], capture_output=True, text=True, timeout=2)
        lines = res.stdout.splitlines()
        history = []
        for line in lines[:100]:
            if not line:
                continue
            parts = line.split("\t", 1)
            cid = parts[0].strip()
            preview = parts[1].strip() if len(parts) > 1 else ""
            if preview:
                history.append({
                    "id": cid,
                    "raw": line,
                    "preview": preview
                })
        return history
    except Exception:
        return []

if __name__ == "__main__":
    print(json.dumps(get_clipboard_history()))
