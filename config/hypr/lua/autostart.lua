-- autostart.lua
-- Applications and processes to start on Hyprland launch

hl.on("hyprland.start", function()
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/wallpaper.sh")  -- Restore last wallpaper via awww
    hl.exec_cmd("env MALLOC_ARENA_MAX=2 quickshell -d")  -- Launch Quickshell (bar + dashboard daemon)
    hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/hyprsunset -i &") -- Blue light / Night light daemon

    hl.exec_cmd("hypridle &")  -- Idle management daemon (screen dim, lock, sleep)
    -- Clipboard history daemon — persistent watchdog loop
    hl.exec_cmd("while true; do wl-paste --watch " .. os.getenv("HOME") .. "/.local/bin/cliphist store || sleep 1; done &")
    -- Pre-warm seamless scratchpad terminal in special:scratchpad
    hl.exec_cmd("systemd-run --user ghostty --gtk-single-instance=false --title=Scratchpad")
end)
