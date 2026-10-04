#!/usr/bin/env python3
import sys, os, json, subprocess, warnings
warnings.filterwarnings("ignore", category=DeprecationWarning)
from PIL import Image

def main():
    if len(sys.argv) < 2:
        print("Usage: theme-engine.py <wall> [scheme] [surface_mode]")
        sys.exit(1)

    home = os.path.expanduser("~")
    preset_file = os.path.join(home, ".cache/hyprdots-preset")

    # Check for curated preset themes (--preset <name>)
    if len(sys.argv) > 1 and sys.argv[1] == "--preset":
        preset = sys.argv[2].lower() if len(sys.argv) > 2 else "tokyonight"
        presets = {
            "catppuccin": {
                "qs": {
                    "bg0": "#1e1e2e", "bg1": "#181825", "bg2": "#313244", "bg3": "#45475a",
                    "fg1": "#cdd6f4", "fg0": "#cdd6f4", "gray": "#a6adc8", "silver": "#585b70",
                    "accent": "#cba6f7", "primary": "#cba6f7", "secondary": "#89b4fa",
                    "tertiary": "#f5c2e7", "red": "#f38ba8"
                },
                "hl": {
                    "bg0": "1e1e2e", "bg1": "181825", "bg2": "313244", "bg3": "45475a",
                    "fg1": "cdd6f4", "primary": "cba6f7", "secondary": "89b4fa", "tertiary": "f5c2e7",
                    "gray": "a6adc8", "silver": "585b70", "red": "f38ba8", "green": "a6e3a1",
                    "yellow": "f9e2af", "blue": "89b4fa", "purple": "cba6f7", "aqua": "94e2d5",
                    "orange": "fab387"
                },
                "ghostty": {
                    "foreground": "#cdd6f4", "background": "#1e1e2e", "cursor": "#f5e0dc",
                    "sel_bg": "#45475a", "sel_fg": "#cdd6f4",
                    "p0": "#45475a", "p1": "#f38ba8", "p2": "#a6e3a1", "p3": "#f9e2af",
                    "p4": "#89b4fa", "p5": "#f5c2e7", "p6": "#94e2d5", "p7": "#bac2de",
                    "p8": "#585b70", "p9": "#f38ba8", "p10": "#a6e3a1", "p11": "#f9e2af",
                    "p12": "#89b4fa", "p13": "#f5c2e7", "p14": "#94e2d5", "p15": "#a6adc8"
                }
            },
            "tokyonight": {
                "qs": {
                    "bg0": "#1a1b26", "bg1": "#16161e", "bg2": "#24283b", "bg3": "#2f3549",
                    "fg1": "#c0caf5", "fg0": "#c0caf5", "gray": "#565f89", "silver": "#414868",
                    "accent": "#7aa2f7", "primary": "#7aa2f7", "secondary": "#bb9af7",
                    "tertiary": "#7dcfff", "red": "#f7768e"
                },
                "hl": {
                    "bg0": "1a1b26", "bg1": "16161e", "bg2": "24283b", "bg3": "2f3549",
                    "fg1": "c0caf5", "primary": "7aa2f7", "secondary": "bb9af7", "tertiary": "7dcfff",
                    "gray": "565f89", "silver": "414868", "red": "f7768e", "green": "9ece6a",
                    "yellow": "e0af68", "blue": "7aa2f7", "purple": "bb9af7", "aqua": "7dcfff",
                    "orange": "ff9e64"
                },
                "ghostty": {
                    "foreground": "#c0caf5", "background": "#1a1b26", "cursor": "#c0caf5",
                    "sel_bg": "#283457", "sel_fg": "#c0caf5",
                    "p0": "#15161e", "p1": "#f7768e", "p2": "#9ece6a", "p3": "#e0af68",
                    "p4": "#7aa2f7", "p5": "#bb9af7", "p6": "#7dcfff", "p7": "#a9b1d6",
                    "p8": "#414868", "p9": "#f7768e", "p10": "#9ece6a", "p11": "#e0af68",
                    "p12": "#7aa2f7", "p13": "#bb9af7", "p14": "#7dcfff", "p15": "#c0caf5"
                }
            },
            "gruvbox": {
                "qs": {
                    "bg0": "#282828", "bg1": "#1d2021", "bg2": "#3c3836", "bg3": "#504945",
                    "fg1": "#ebdbb2", "fg0": "#ebdbb2", "gray": "#a89984", "silver": "#665c54",
                    "accent": "#fe8019", "primary": "#fe8019", "secondary": "#fabd2f",
                    "tertiary": "#b8bb26", "red": "#fb4934"
                },
                "hl": {
                    "bg0": "282828", "bg1": "1d2021", "bg2": "3c3836", "bg3": "504945",
                    "fg1": "ebdbb2", "primary": "fe8019", "secondary": "fabd2f", "tertiary": "b8bb26",
                    "gray": "a89984", "silver": "665c54", "red": "fb4934", "green": "b8bb26",
                    "yellow": "fabd2f", "blue": "83a598", "purple": "d3869b", "aqua": "8ec07c",
                    "orange": "fe8019"
                },
                "ghostty": {
                    "foreground": "#ebdbb2", "background": "#282828", "cursor": "#ebdbb2",
                    "sel_bg": "#504945", "sel_fg": "#ebdbb2",
                    "p0": "#282828", "p1": "#cc241d", "p2": "#98971a", "p3": "#d79921",
                    "p4": "#458588", "p5": "#b16286", "p6": "#689d6a", "p7": "#a89984",
                    "p8": "#928374", "p9": "#fb4934", "p10": "#b8bb26", "p11": "#fabd2f",
                    "p12": "#83a598", "p13": "#d3869b", "p14": "#8ec07c", "p15": "#ebdbb2"
                }
            },
            "nord": {
                "qs": {
                    "bg0": "#2e3440", "bg1": "#242933", "bg2": "#3b4252", "bg3": "#434c5e",
                    "fg1": "#eceff4", "fg0": "#eceff4", "gray": "#d8dee9", "silver": "#4c566a",
                    "accent": "#88c0d0", "primary": "#88c0d0", "secondary": "#81a1c1",
                    "tertiary": "#8fbcbb", "red": "#bf616a"
                },
                "hl": {
                    "bg0": "2e3440", "bg1": "242933", "bg2": "3b4252", "bg3": "434c5e",
                    "fg1": "eceff4", "primary": "88c0d0", "secondary": "81a1c1", "tertiary": "8fbcbb",
                    "gray": "d8dee9", "silver": "4c566a", "red": "bf616a", "green": "a3be8c",
                    "yellow": "ebcb8b", "blue": "81a1c1", "purple": "b48ead", "aqua": "88c0d0",
                    "orange": "d08770"
                },
                "ghostty": {
                    "foreground": "#eceff4", "background": "#2e3440", "cursor": "#d8dee9",
                    "sel_bg": "#434c5e", "sel_fg": "#eceff4",
                    "p0": "#3b4252", "p1": "#bf616a", "p2": "#a3be8c", "p3": "#ebcb8b",
                    "p4": "#81a1c1", "p5": "#b48ead", "p6": "#88c0d0", "p7": "#e5e9f0",
                    "p8": "#4c566a", "p9": "#bf616a", "p10": "#a3be8c", "p11": "#ebcb8b",
                    "p12": "#81a1c1", "p13": "#b48ead", "p14": "#8fbcbb", "p15": "#eceff4"
                }
            },
            "cyberpunk": {
                "qs": {
                    "bg0": "#08080c", "bg1": "#101018", "bg2": "#1a1a26", "bg3": "#262638",
                    "fg1": "#f0e8ff", "fg0": "#f0e8ff", "gray": "#7b7799", "silver": "#3d3856",
                    "accent": "#ff007f", "primary": "#ff007f", "secondary": "#00f0ff",
                    "tertiary": "#ffe600", "red": "#ff3366"
                },
                "hl": {
                    "bg0": "08080c", "bg1": "101018", "bg2": "1a1a26", "bg3": "262638",
                    "fg1": "f0e8ff", "primary": "ff007f", "secondary": "00f0ff", "tertiary": "ffe600",
                    "gray": "7b7799", "silver": "3d3856", "red": "ff3366", "green": "00ff9f",
                    "yellow": "ffe600", "blue": "00f0ff", "purple": "ff007f", "aqua": "00f0ff",
                    "orange": "ff9900"
                },
                "ghostty": {
                    "foreground": "#f0e8ff", "background": "#08080c", "cursor": "#00f0ff",
                    "sel_bg": "#262638", "sel_fg": "#00f0ff",
                    "p0": "#08080c", "p1": "#ff3366", "p2": "#00ff9f", "p3": "#ffe600",
                    "p4": "#00f0ff", "p5": "#ff007f", "p6": "#00f0ff", "p7": "#f0e8ff",
                    "p8": "#3d3856", "p9": "#ff3366", "p10": "#00ff9f", "p11": "#ffe600",
                    "p12": "#00f0ff", "p13": "#ff007f", "p14": "#00f0ff", "p15": "#ffffff"
                }
            },
            "rosepine": {
                "qs": {
                    "bg0": "#191724", "bg1": "#1f1d2e", "bg2": "#26233a", "bg3": "#393552",
                    "fg1": "#e0def4", "fg0": "#e0def4", "gray": "#908caa", "silver": "#6e6a86",
                    "accent": "#ebbcba", "primary": "#ebbcba", "secondary": "#f6c177",
                    "tertiary": "#9ccfd8", "red": "#eb6f92"
                },
                "hl": {
                    "bg0": "191724", "bg1": "1f1d2e", "bg2": "26233a", "bg3": "393552",
                    "fg1": "e0def4", "primary": "ebbcba", "secondary": "f6c177", "tertiary": "9ccfd8",
                    "gray": "908caa", "silver": "6e6a86", "red": "eb6f92", "green": "31748f",
                    "yellow": "f6c177", "blue": "9ccfd8", "purple": "c4a7e7", "aqua": "ebbcba",
                    "orange": "ea9a97"
                },
                "ghostty": {
                    "foreground": "#e0def4", "background": "#191724", "cursor": "#524f67",
                    "sel_bg": "#2a283e", "sel_fg": "#e0def4",
                    "p0": "#26233a", "p1": "#eb6f92", "p2": "#31748f", "p3": "#f6c177",
                    "p4": "#9ccfd8", "p5": "#c4a7e7", "p6": "#ebbcba", "p7": "#e0def4",
                    "p8": "#6e6a86", "p9": "#eb6f92", "p10": "#31748f", "p11": "#f6c177",
                    "p12": "#9ccfd8", "p13": "#c4a7e7", "p14": "#ebbcba", "p15": "#e0def4"
                }
            },
            "blood_crimson": {
                "qs": {
                    "bg0": "#08080c", "bg1": "#100e14", "bg2": "#18121a", "bg3": "#261620",
                    "fg1": "#f5e6e8", "fg0": "#f5e6e8", "gray": "#8a666e", "silver": "#4a2a32",
                    "accent": "#ff4d5a", "primary": "#ff4d5a", "secondary": "#ff7582",
                    "tertiary": "#ff2a42", "red": "#ff1744"
                },
                "hl": {
                    "bg0": "08080c", "bg1": "100e14", "bg2": "18121a", "bg3": "261620",
                    "fg1": "f5e6e8", "primary": "ff4d5a", "secondary": "ff7582", "tertiary": "ff2a42",
                    "gray": "8a666e", "silver": "4a2a32", "red": "ff1744", "green": "ff7582",
                    "yellow": "ffa4ad", "blue": "ff4d5a", "purple": "ff2a42", "aqua": "ff7582",
                    "orange": "ff5252"
                },
                "ghostty": {
                    "foreground": "#f5e6e8", "background": "#08080c", "cursor": "#ff4d5a",
                    "sel_bg": "#261620", "sel_fg": "#ffffff",
                    "p0": "#08080c", "p1": "#ff1744", "p2": "#ff7582", "p3": "#ffa4ad",
                    "p4": "#ff4d5a", "p5": "#ff2a42", "p6": "#ff7582", "p7": "#f5e6e8",
                    "p8": "#4a2a32", "p9": "#ff1744", "p10": "#ff7582", "p11": "#ffa4ad",
                    "p12": "#ff4d5a", "p13": "#ff2a42", "p14": "#ff7582", "p15": "#ffffff"
                }
            },
            "samurai_steel": {
                "qs": {
                    "bg0": "#0a0a0e", "bg1": "#121218", "bg2": "#1a1a22", "bg3": "#262632",
                    "fg1": "#f3f4f6", "fg0": "#f3f4f6", "gray": "#6b7280", "silver": "#374151",
                    "accent": "#f3f4f6", "primary": "#f3f4f6", "secondary": "#d1d5db",
                    "tertiary": "#9ca3af", "red": "#ff5449"
                },
                "hl": {
                    "bg0": "0a0a0e", "bg1": "121218", "bg2": "1a1a22", "bg3": "262632",
                    "fg1": "f3f4f6", "primary": "f3f4f6", "secondary": "d1d5db", "tertiary": "9ca3af",
                    "gray": "6b7280", "silver": "374151", "red": "ff5449", "green": "9ca3af",
                    "yellow": "d1d5db", "blue": "f3f4f6", "purple": "d1d5db", "aqua": "374151",
                    "orange": "9ca3af"
                },
                "ghostty": {
                    "foreground": "#f3f4f6", "background": "#0a0a0e", "cursor": "#f3f4f6",
                    "sel_bg": "#262632", "sel_fg": "#ffffff",
                    "p0": "#0a0a0e", "p1": "#ff5449", "p2": "#9ca3af", "p3": "#d1d5db",
                    "p4": "#f3f4f6", "p5": "#9ca3af", "p6": "#d1d5db", "p7": "#f3f4f6",
                    "p8": "#374151", "p9": "#ff5449", "p10": "#9ca3af", "p11": "#d1d5db",
                    "p12": "#f3f4f6", "p13": "#9ca3af", "p14": "#d1d5db", "p15": "#ffffff"
                }
            },
            "amoled": {
                "qs": {
                    "bg0": "#000000", "bg1": "#080808", "bg2": "#121212", "bg3": "#1c1c1c",
                    "fg1": "#f3f4f6", "fg0": "#ffffff", "gray": "#71717a", "silver": "#27272a",
                    "accent": "#ffffff", "primary": "#ffffff", "secondary": "#a1a1aa",
                    "tertiary": "#71717a", "red": "#ef4444"
                },
                "hl": {
                    "bg0": "000000", "bg1": "080808", "bg2": "121212", "bg3": "1c1c1c",
                    "fg1": "f3f4f6", "primary": "ffffff", "secondary": "a1a1aa", "tertiary": "71717a",
                    "gray": "71717a", "silver": "27272a", "red": "ef4444", "green": "10b981",
                    "yellow": "f59e0b", "blue": "3b82f6", "purple": "8b5cf6", "aqua": "06b6d4",
                    "orange": "f97316"
                },
                "ghostty": {
                    "foreground": "#ffffff", "background": "#000000", "cursor": "#ffffff",
                    "sel_bg": "#1c1c1c", "sel_fg": "#ffffff",
                    "p0": "#000000", "p1": "#ef4444", "p2": "#10b981", "p3": "#f59e0b",
                    "p4": "#3b82f6", "p5": "#8b5cf6", "p6": "#06b6d4", "p7": "#f3f4f6",
                    "p8": "#27272a", "p9": "#ef4444", "p10": "#10b981", "p11": "#f59e0b",
                    "p12": "#3b82f6", "p13": "#8b5cf6", "p14": "#06b6d4", "p15": "#ffffff"
                }
            }
        }
        presets["blood"] = presets["blood_crimson"]
        presets["crimson"] = presets["blood_crimson"]
        presets["steel"] = presets["samurai_steel"]
        presets["monochrome"] = presets["samurai_steel"]
        presets["pitch_black"] = presets["amoled"]
        selected = presets.get(preset, presets["tokyonight"])
        qs = selected["qs"]
        hl = selected["hl"]
        ghostty = selected["ghostty"]
        surface_mode = "preset-" + preset
        try:
            with open(preset_file, "w") as f:
                f.write(preset)
        except Exception:
            pass
    else:
        try:
            with open(preset_file, "w") as f:
                f.write("dynamic")
        except Exception:
            pass

        wall = sys.argv[1]
        scheme = sys.argv[2] if len(sys.argv) > 2 and sys.argv[2] else "scheme-vibrant"
        surface_mode = sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] else "obsidian"

        matugen_bin = os.path.join(home, ".local/bin/matugen")
        if not os.path.exists(matugen_bin):
            matugen_bin = "matugen"

        # Fast check for grayscale / B&W manga sketches
        is_grayscale = False
        try:
            im = Image.open(wall).convert("RGB")
            im.thumbnail((50, 50))
            px = list(im.getdata())
            bright_px = [(r,g,b) for r,g,b in px if (0.299*r + 0.587*g + 0.114*b) >= 20]
            if not bright_px:
                is_grayscale = True
            else:
                sats = [max(r,g,b) - min(r,g,b) for r,g,b in bright_px]
                if (sum(sats) / len(sats)) < 14:
                    is_grayscale = True
        except Exception as e:
            print("Error checking saturation:", e)

        if is_grayscale:
            if surface_mode == "amoled":
                bg0, bg1, bg2, bg3 = "#000000", "#080808", "#121212", "#1c1c1c"
                hl_bg0, hl_bg1, hl_bg2, hl_bg3 = "000000", "080808", "121212", "1c1c1c"
                ghostty_bg = "#000000"
                prim, sec, tert = "#ffffff", "#a1a1aa", "#71717a"
                red = "#ff5449"
            elif surface_mode in ["blood", "crimson", "blood_crimson"]:
                bg0, bg1, bg2, bg3 = "#08080c", "#100e14", "#18121a", "#261620"
                hl_bg0, hl_bg1, hl_bg2, hl_bg3 = "08080c", "100e14", "18121a", "261620"
                ghostty_bg = "#08080c"
                prim, sec, tert = "#ff4d5a", "#ff7582", "#ff2a42"
                red = "#ff1744"
            elif surface_mode in ["steel", "monochrome", "samurai_steel"]:
                bg0, bg1, bg2, bg3 = "#0a0a0e", "#121218", "#1a1a22", "#262632"
                hl_bg0, hl_bg1, hl_bg2, hl_bg3 = "0a0a0e", "121218", "1a1a22", "262632"
                ghostty_bg = "#0a0a0e"
                prim, sec, tert = "#f3f4f6", "#d1d5db", "#9ca3af"
                red = "#ff5449"
            elif surface_mode == "material":
                bg0, bg1, bg2, bg3 = "#141418", "#1b1b22", "#23232c", "#2d2d38"
                hl_bg0, hl_bg1, hl_bg2, hl_bg3 = "141418", "1b1b22", "23232c", "2d2d38"
                ghostty_bg = "#141418"
                prim, sec, tert = "#e4e4e7", "#a1a1aa", "#71717a"
                red = "#ff5449"
            else: # obsidian (default)
                bg0, bg1, bg2, bg3 = "#0b0c10", "#121318", "#181a20", "#22242c"
                hl_bg0, hl_bg1, hl_bg2, hl_bg3 = "0b0c10", "121318", "181a20", "22242c"
                ghostty_bg = "#0b0c10"
                prim, sec, tert = "#f3f4f6", "#d1d5db", "#9ca3af"
                red = "#ff5449"

            qs = {
                "bg0": bg0, "bg1": bg1, "bg2": bg2, "bg3": bg3,
                "fg1": "#f3f4f6", "fg0": "#f3f4f6", "gray": "#6b7280", "silver": "#374151",
                "accent": prim, "primary": prim, "secondary": sec,
                "tertiary": tert, "red": red
            }
            hl = {
                "bg0": hl_bg0, "bg1": hl_bg1, "bg2": hl_bg2, "bg3": hl_bg3,
                "fg1": "f3f4f6", "primary": prim.lstrip("#"), "secondary": sec.lstrip("#"), "tertiary": tert.lstrip("#"),
                "gray": "6b7280", "silver": "374151", "red": red.lstrip("#"), "green": tert.lstrip("#"),
                "yellow": sec.lstrip("#"), "blue": prim.lstrip("#"), "purple": sec.lstrip("#"), "aqua": "374151",
                "orange": tert.lstrip("#")
            }
            ghostty = {
                "foreground": "#f3f4f6", "background": ghostty_bg, "cursor": prim,
                "sel_bg": bg3, "sel_fg": "#ffffff",
                "p0": ghostty_bg, "p1": red, "p2": tert, "p3": sec,
                "p4": prim, "p5": tert, "p6": sec, "p7": "#f3f4f6",
                "p8": "#374151", "p9": red, "p10": tert, "p11": sec,
                "p12": prim, "p13": tert, "p14": sec, "p15": "#ffffff"
            }
        else:
            # Run Matugen to get full Material You tonal palette
            cmd = [matugen_bin, "image", wall, "--type", scheme, "--source-color-index", "0", "--dry-run", "-j", "hex"]
            res = subprocess.run(cmd, capture_output=True, text=True)
            if res.returncode != 0:
                print("Matugen error:", res.stderr)
                sys.exit(1)
            raw = json.loads(res.stdout)
            c = raw["colors"]

            prim = c["primary"]["default"]["color"]
            sec = c["secondary"]["default"]["color"]
            tert = c["tertiary"]["default"]["color"]
            on_surf = c["on_surface"]["default"]["color"]
            outline = c["outline"]["default"]["color"]
            outline_var = c["outline_variant"]["default"]["color"]
            err = c["error"]["default"]["color"]
            err_cont = c["error_container"]["default"]["color"]
            surf_high = c["surface_container_highest"]["default"]["color"]
            prim_cont = c["primary_container"]["default"]["color"]
            sec_cont = c["secondary_container"]["default"]["color"]
            tert_cont = c["tertiary_container"]["default"]["color"]

            if surface_mode == "amoled":
                bg0, bg1, bg2, bg3 = "#000000", "#080808", "#121212", "#1c1c1c"
                hl_bg0, hl_bg1, hl_bg2, hl_bg3 = "000000", "080808", "121212", "1c1c1c"
                ghostty_bg = "#000000"
            elif surface_mode in ["blood", "crimson", "blood_crimson"]:
                bg0, bg1, bg2, bg3 = "#08080c", "#100e14", "#18121a", "#261620"
                hl_bg0, hl_bg1, hl_bg2, hl_bg3 = "08080c", "100e14", "18121a", "261620"
                ghostty_bg = "#08080c"
                prim = "#ff4d5a"
                sec = "#ff7582"
                tert = "#ff2a42"
                err = "#ff1744"
            elif surface_mode in ["steel", "monochrome", "samurai_steel"]:
                bg0, bg1, bg2, bg3 = "#0a0a0e", "#121218", "#1a1a22", "#262632"
                hl_bg0, hl_bg1, hl_bg2, hl_bg3 = "0a0a0e", "121218", "1a1a22", "262632"
                ghostty_bg = "#0a0a0e"
                prim = "#f3f4f6"
                sec = "#d1d5db"
                tert = "#9ca3af"
            elif surface_mode == "obsidian":
                bg0, bg1, bg2, bg3 = "#0b0c10", "#121318", "#181a20", "#22242c"
                hl_bg0, hl_bg1, hl_bg2, hl_bg3 = "0b0c10", "121318", "181a20", "22242c"
                ghostty_bg = "#0b0c10"
            else: # material
                bg0 = c["background"]["default"]["color"]
                bg1 = c["surface_container_low"]["default"]["color"]
                bg2 = c["surface_container"]["default"]["color"]
                bg3 = c["surface_container_high"]["default"]["color"]
                hl_bg0 = bg0.lstrip("#")
                hl_bg1 = bg1.lstrip("#")
                hl_bg2 = bg2.lstrip("#")
                hl_bg3 = bg3.lstrip("#")
                ghostty_bg = bg0

            qs = {
                "bg0": bg0, "bg1": bg1, "bg2": bg2, "bg3": bg3,
                "fg1": on_surf, "fg0": on_surf, "gray": outline, "silver": outline_var,
                "accent": prim, "primary": prim, "secondary": sec, "tertiary": tert, "red": err
            }
            hl = {
                "bg0": hl_bg0, "bg1": hl_bg1, "bg2": hl_bg2, "bg3": hl_bg3,
                "fg1": on_surf.lstrip("#"), "primary": prim.lstrip("#"),
                "secondary": sec.lstrip("#"), "tertiary": tert.lstrip("#"),
                "gray": outline.lstrip("#"), "silver": outline_var.lstrip("#"),
                "red": err.lstrip("#"), "green": tert.lstrip("#"),
                "yellow": prim_cont.lstrip("#"), "blue": prim.lstrip("#"),
                "purple": sec.lstrip("#"), "aqua": sec_cont.lstrip("#"),
                "orange": tert_cont.lstrip("#")
            }
            ghostty = {
                "foreground": on_surf, "background": ghostty_bg, "cursor": prim,
                "sel_bg": surf_high, "sel_fg": on_surf,
                "p0": ghostty_bg, "p1": err, "p2": tert, "p3": sec_cont,
                "p4": prim, "p5": tert_cont, "p6": sec, "p7": on_surf,
                "p8": outline_var, "p9": err_cont, "p10": tert, "p11": sec,
                "p12": prim_cont, "p13": tert, "p14": sec_cont, "p15": on_surf
            }

    # 1. Write Quickshell colors.json
    qs_path = os.path.join(home, ".config/quickshell/colors.json")
    os.makedirs(os.path.dirname(qs_path), exist_ok=True)
    with open(qs_path, "w") as f:
        json.dump(qs, f, indent=2)

    # 2. Write Hyprland colors.lua
    hl_path = os.path.join(home, ".config/hypr/lua/colors.lua")
    os.makedirs(os.path.dirname(hl_path), exist_ok=True)
    with open(hl_path, "w") as f:
        f.write("-- colors.lua (Auto-generated by Theme Engine)\n")
        f.write("local colors = {\n")
        for k, v in hl.items():
            f.write(f"  {k:7} = \"{v}\",\n")
        f.write("}\nreturn colors\n")

    # 3. Write Ghostty theme
    gh_path = os.path.join(home, ".config/ghostty/theme")
    os.makedirs(os.path.dirname(gh_path), exist_ok=True)
    with open(gh_path, "w") as f:
        f.write("# Auto-generated by Theme Engine\n")
        f.write(f"foreground       = {ghostty['foreground']}\n")
        f.write(f"background       = {ghostty['background']}\n")
        f.write(f"cursor-color     = {ghostty['cursor']}\n")
        f.write(f"selection-background = {ghostty['sel_bg']}\n")
        f.write(f"selection-foreground = {ghostty['sel_fg']}\n\n")
        for i in range(16):
            f.write(f"palette = {i}={ghostty[f'p{i}']}\n")

    # 4. Write VS Code theme customizations
    vscode_path = os.path.join(home, ".config/Code/User/settings.json")
    try:
        vscode_settings = {}
        if os.path.exists(vscode_path):
            with open(vscode_path, "r", encoding="utf-8") as f:
                try:
                    vscode_settings = json.load(f)
                except Exception:
                    vscode_settings = {}
        else:
            os.makedirs(os.path.dirname(vscode_path), exist_ok=True)

        vscode_colors = {
            "editor.background": qs["bg0"],
            "editor.foreground": qs["fg1"],
            "editorLineNumber.foreground": qs["gray"],
            "editorLineNumber.activeForeground": qs["accent"],
            "sideBar.background": qs["bg1"],
            "sideBar.foreground": qs["fg1"],
            "sideBarSectionHeader.background": qs["bg2"],
            "sideBarSectionHeader.foreground": qs["fg1"],
            "activityBar.background": qs["bg1"],
            "activityBar.foreground": qs["accent"],
            "activityBar.activeBorder": qs["accent"],
            "statusBar.background": qs["bg1"],
            "statusBar.foreground": qs["fg1"],
            "statusBarItem.remoteBackground": qs["accent"],
            "titleBar.activeBackground": qs["bg0"],
            "titleBar.activeForeground": qs["fg1"],
            "titleBar.inactiveBackground": qs["bg0"],
            "titleBar.inactiveForeground": qs["gray"],
            "tab.activeBackground": qs["bg2"],
            "tab.activeForeground": qs["fg1"],
            "tab.inactiveBackground": qs["bg0"],
            "tab.inactiveForeground": qs["gray"],
            "tab.activeBorder": qs["accent"],
            "editorGroupHeader.tabsBackground": qs["bg0"],
            "terminal.background": qs["bg0"],
            "terminal.foreground": qs["fg1"],
            "focusBorder": qs["accent"],
        }
        vscode_settings["workbench.colorCustomizations"] = vscode_colors
        with open(vscode_path, "w", encoding="utf-8") as f:
            json.dump(vscode_settings, f, indent=4)
    except Exception as e:
        print("VS Code theme sync error:", e)

    # 5. Write Neovim colors.lua
    nvim_colors_path = os.path.join(home, ".config/nvim/lua/colors.lua")
    try:
        os.makedirs(os.path.dirname(nvim_colors_path), exist_ok=True)
        with open(nvim_colors_path, "w", encoding="utf-8") as f:
            f.write("-- ~/.config/nvim/lua/colors.lua\n")
            f.write("-- Auto-generated by Theme Engine\n")
            f.write("local M = {\n")
            for k, v in qs.items():
                f.write(f'  {k} = "{v}",\n')
            f.write("}\n\n")
            f.write("local hl = vim.api.nvim_set_hl\n")
            f.write('hl(0, "Normal", { bg = M.bg0, fg = M.fg1 })\n')
            f.write('hl(0, "NormalFloat", { bg = M.bg1, fg = M.fg1 })\n')
            f.write('hl(0, "FloatBorder", { bg = M.bg1, fg = M.accent })\n')
            f.write('hl(0, "CursorLine", { bg = M.bg1 })\n')
            f.write('hl(0, "LineNr", { fg = M.gray })\n')
            f.write('hl(0, "CursorLineNr", { fg = M.accent, bold = true })\n')
            f.write('hl(0, "StatusLine", { bg = M.bg1, fg = M.fg1 })\n')
            f.write('hl(0, "StatusLineNC", { bg = M.bg0, fg = M.gray })\n')
            f.write('hl(0, "Pmenu", { bg = M.bg1, fg = M.fg1 })\n')
            f.write('hl(0, "PmenuSel", { bg = M.accent, fg = M.bg0 })\n')
            f.write('hl(0, "Visual", { bg = M.bg2 })\n')
            f.write('hl(0, "SignColumn", { bg = M.bg0 })\n\n')
            f.write("return M\n")
    except Exception as e:
        print("Neovim theme sync error:", e)

    print(f"Theme generated successfully ({surface_mode}): {qs['bg0']} / {qs['accent']}")

if __name__ == "__main__":
    main()
