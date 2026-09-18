#!/usr/bin/env python3
import os
import sys
import json
import glob

def build_icon_map():
    icon_map = {}
    search_dirs = [
        "/usr/share/pixmaps",
        "/usr/share/icons/hicolor",
        os.path.expanduser("~/.local/share/icons"),
        "/usr/share/icons/AdwaitaLegacy",
        "/usr/share/icons",
    ]
    for sdir in search_dirs:
        if not os.path.exists(sdir):
            continue
        for root, _, files in os.walk(sdir):
            for f in files:
                if f.endswith((".png", ".svg", ".xpm")):
                    stem, _ = os.path.splitext(f)
                    full = os.path.join(root, f)
                    if stem not in icon_map or (".svg" in full or "128" in full or "256" in full or "scalable" in full):
                        icon_map[stem] = full
                    if f not in icon_map:
                        icon_map[f] = full
    return icon_map

def get_installed_apps():
    dirs = [
        os.path.expanduser("~/.local/share/applications"),
        "/usr/share/applications",
        "/var/lib/flatpak/exports/share/applications",
        os.path.expanduser("~/.local/share/flatpak/exports/share/applications"),
    ]
    apps = []
    seen = set()

    # Load frecency cache
    frecency = {}
    cache_file = os.path.expanduser("~/.cache/quickshell-launcher-frecency.json")
    if os.path.exists(cache_file):
        try:
            with open(cache_file, "r") as f:
                frecency = json.load(f)
        except Exception:
            pass

    icon_map = build_icon_map()

    for d in dirs:
        if not os.path.exists(d):
            continue
        for path in glob.glob(os.path.join(d, "*.desktop")):
            try:
                with open(path, "r", encoding="utf-8", errors="ignore") as f:
                    name = ""
                    exec_cmd = ""
                    icon = ""
                    generic_name = ""
                    comment = ""
                    keywords = ""
                    nodisplay = False
                    is_terminal = False

                    for line in f:
                        line = line.strip()
                        if line == "[Desktop Entry]":
                            continue
                        if line.startswith("[") and line.endswith("]"):
                            break # Primary entry ends when sub-action starts
                        
                        if line.startswith("Name=") and not name:
                            name = line.split("=", 1)[1]
                        elif line.startswith("GenericName=") and not generic_name:
                            generic_name = line.split("=", 1)[1]
                        elif line.startswith("Comment=") and not comment:
                            comment = line.split("=", 1)[1]
                        elif line.startswith("Keywords=") and not keywords:
                            keywords = line.split("=", 1)[1].replace(";", " ")
                        elif line.startswith("Exec=") and not exec_cmd:
                            exec_cmd = line.split("=", 1)[1]
                        elif line.startswith("Icon=") and not icon:
                            icon = line.split("=", 1)[1]
                        elif line.startswith("NoDisplay=true") or line.startswith("Hidden=true"):
                            nodisplay = True
                        elif line.startswith("Terminal=true"):
                            is_terminal = True

                    if name and exec_cmd and not nodisplay and name not in seen:
                        seen.add(name)
                        
                        # Strip Desktop Exec variables like %f, %U, @@, etc.
                        clean_exec_parts = []
                        for arg in exec_cmd.split():
                            if arg.startswith("%") or arg.startswith("@@"):
                                continue
                            clean_exec_parts.append(arg)
                        clean_exec = " ".join(clean_exec_parts)

                        # Wrap terminal apps
                        if is_terminal:
                            clean_exec = f"ghostty -e {clean_exec}"

                        sub_label = generic_name if generic_name else (comment[:50] if comment else clean_exec)
                        search_blob = f"{name} {generic_name} {keywords} {comment} {clean_exec}".lower()

                        # Resolve icon file path
                        resolved_icon_path = ""
                        if icon:
                            if os.path.isabs(icon) and os.path.exists(icon):
                                resolved_icon_path = icon
                            elif icon in icon_map:
                                resolved_icon_path = icon_map[icon]
                            else:
                                base_icon = os.path.splitext(icon)[0]
                                if base_icon in icon_map:
                                    resolved_icon_path = icon_map[base_icon]

                        count = frecency.get(name, 0)
                        apps.append({
                            "name": name,
                            "subtitle": sub_label,
                            "exec": clean_exec,
                            "icon": icon or "application-x-executable",
                            "iconPath": resolved_icon_path,
                            "search": search_blob,
                            "score": count
                        })
            except Exception:
                pass

    # Sort first by launch count descending, then alphabetically by name
    apps.sort(key=lambda x: (-x["score"], x["name"].lower()))
    return apps

if __name__ == "__main__":
    print(json.dumps(get_installed_apps()))
