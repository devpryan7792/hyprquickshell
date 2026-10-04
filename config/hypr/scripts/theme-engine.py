#!/usr/bin/env python3
import sys, os, json, subprocess, warnings
warnings.filterwarnings("ignore", category=DeprecationWarning)
from PIL import Image

def main():
    if len(sys.argv) < 2:
        print("Usage: theme-engine.py <wall> [scheme] [surface_mode]")
        sys.exit(1)

    wall = sys.argv[1]
    scheme = sys.argv[2] if len(sys.argv) > 2 and sys.argv[2] else "scheme-vibrant"
    surface_mode = sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] else "obsidian"

    home = os.path.expanduser("~")
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
        # Samurai Steel Monochrome (eliminates fake Google Blue #4285F4 fallback)
        qs = {
            "bg0": "#0b0c10", "bg1": "#121318", "bg2": "#181a20", "bg3": "#22242c",
            "fg1": "#f3f4f6", "fg0": "#f3f4f6", "gray": "#6b7280", "silver": "#374151",
            "accent": "#f3f4f6", "primary": "#f3f4f6", "secondary": "#d1d5db",
            "tertiary": "#9ca3af", "red": "#ff5449"
        }
        hl = {
            "bg0": "0b0c10", "bg1": "121318", "bg2": "181a20", "bg3": "22242c",
            "fg1": "f3f4f6", "primary": "f3f4f6", "secondary": "d1d5db", "tertiary": "9ca3af",
            "gray": "6b7280", "silver": "374151", "red": "ff5449", "green": "9ca3af",
            "yellow": "d1d5db", "blue": "f3f4f6", "purple": "d1d5db", "aqua": "374151",
            "orange": "9ca3af"
        }
        ghostty = {
            "foreground": "#f3f4f6", "background": "#0b0c10", "cursor": "#f3f4f6",
            "sel_bg": "#374151", "sel_fg": "#ffffff",
            "p0": "#0b0c10", "p1": "#ff5449", "p2": "#9ca3af", "p3": "#d1d5db",
            "p4": "#f3f4f6", "p5": "#9ca3af", "p6": "#d1d5db", "p7": "#f3f4f6",
            "p8": "#374151", "p9": "#ff5449", "p10": "#9ca3af", "p11": "#d1d5db",
            "p12": "#f3f4f6", "p13": "#9ca3af", "p14": "#d1d5db", "p15": "#ffffff"
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

        if surface_mode == "obsidian":
            bg0, bg1, bg2, bg3 = "#0b0c10", "#121318", "#181a20", "#22242c"
            hl_bg0, hl_bg1, hl_bg2, hl_bg3 = "0b0c10", "121318", "181a20", "22242c"
            ghostty_bg = "#0b0c10"
        else:
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

    print(f"Theme generated successfully ({surface_mode}): {qs['bg0']} / {qs['accent']}")

if __name__ == "__main__":
    main()
