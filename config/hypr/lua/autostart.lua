-- autostart.lua
-- Applications and processes to start on Hyprland launch

local home = os.getenv("HOME")

hl.on("hyprland.start", function()
    -- Restore last wallpaper via awww
    hl.exec_cmd(home .. "/.config/hypr/scripts/wallpaper.sh")

    -- Launch Quickshell (bar + dashboard daemon)
    hl.exec_cmd("quickshell -d")

    -- Blue light / Night light daemon (checks PATH and ~/.local/bin)
    hl.exec_cmd("sh -c 'if command -v hyprsunset >/dev/null 2>&1; then hyprsunset -i; elif [ -x \"$HOME/.local/bin/hyprsunset\" ]; then \"$HOME/.local/bin/hyprsunset\" -i; fi' &")

    -- Clipboard history daemon — persistent watchdog loop
    hl.exec_cmd("sh -c 'CLIP_BIN=$(command -v cliphist 2>/dev/null || echo \"$HOME/.local/bin/cliphist\"); while true; do wl-paste --watch \"$CLIP_BIN\" store || sleep 1; done' &")
end)
