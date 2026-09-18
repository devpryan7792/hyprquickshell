-- =============================================================================
-- binds.lua — Hyprland Keybindings & Mouse Mappings
-- Deduped: SUPER+Q only, SUPER+SPACE only, SUPER+W only, SUPER+N only, SUPER+F4 only
-- =============================================================================

local mainMod = "SUPER"
local home = os.getenv("HOME")

-- ── Applications ─────────────────────────────────────────────────────────────
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("ghostty"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("thunar"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("which brave >/dev/null 2>&1 && brave || (which brave-browser >/dev/null 2>&1 && brave-browser || firefox)"))

-- ── Quickshell Integrations (Replaced Rofi & Waybar) ──────────────────
-- App Launcher (Spotlight)
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("quickshell ipc call launcher toggle"))

-- Clipboard History
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("quickshell ipc call launcher clip"))

-- Wallpaper & Dynamic Theming (SUPER+W, SUPER+SHIFT+W, ALT+T, SUPER+SHIFT+T)
hl.bind(mainMod .. " + W",           hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/toggle-wallpaper.sh"))
hl.bind(mainMod .. " + SHIFT + W",   hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/toggle-wallpaper.sh"))
hl.bind(mainMod .. " + ALT + W",     hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/toggle-wallpaper.sh"))
hl.bind("ALT + T",                   hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/toggle-wallpaper.sh"))
hl.bind(mainMod .. " + SHIFT + T",   hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/toggle-wallpaper.sh"))

-- Control Center / Dashboard Side Panel
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("quickshell ipc call dashboard toggle"))

-- Blue Light / Night Light Filter (cycle Off -> 4500K -> 3500K -> 2700K -> Off)
hl.bind(mainMod .. " + ALT + N",   hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/bluelight.sh toggle"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/bluelight.sh toggle"))

-- ── Session / Power ──────────────────────────────────────────────────────
-- Exit Hyprland compositor
hl.bind(mainMod .. " + M", hl.dsp.exit())

-- ── Window Management ────────────────────────────────────────────────────
-- Kill active window (SUPER+F4)
hl.bind(mainMod .. " + F4", hl.dsp.window.close())

-- Toggle floating (SUPER+T per README)
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }))

-- Toggle fullscreen (SUPER+F per repo config)
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())

-- Pseudo-tile & Split
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

-- ── Focus Navigation ─────────────────────────────────────────────────────────
-- Arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Vim navigation keys
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))

-- ── Window Movement ──────────────────────────────────────────────────────────
-- Move active window (SUPER + SHIFT + Arrows / Vim keys)
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

hl.bind(mainMod .. " + SHIFT + H",     hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + J",     hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + K",     hl.dsp.window.move({ direction = "up" }))

-- ── Window Resizing ──────────────────────────────────────────────────────
-- Resize active window (SUPER + ALT + Arrows / Vim keys)
hl.bind(mainMod .. " + ALT + left",  hl.dsp.exec_cmd("hyprctl dispatch resizeactive -30 0"),  { repeating = true })
hl.bind(mainMod .. " + ALT + right", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 30 0"),   { repeating = true })
hl.bind(mainMod .. " + ALT + up",    hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 -30"),  { repeating = true })
hl.bind(mainMod .. " + ALT + down",  hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 30"),   { repeating = true })

hl.bind(mainMod .. " + ALT + H",     hl.dsp.exec_cmd("hyprctl dispatch resizeactive -30 0"),  { repeating = true })
hl.bind(mainMod .. " + ALT + L",     hl.dsp.exec_cmd("hyprctl dispatch resizeactive 30 0"),   { repeating = true })
hl.bind(mainMod .. " + ALT + K",     hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 -30"),  { repeating = true })
hl.bind(mainMod .. " + ALT + J",     hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 30"),   { repeating = true })

-- ── Screenshots (grim + slurp) ───────────────────────────────────────────
-- Print -> region, SHIFT+Print -> window, SUPER+Print -> window
hl.bind("Print",                          hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/screenshot.sh region"))
hl.bind("SHIFT + Print",                  hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/screenshot.sh window"))
hl.bind(mainMod .. " + Print",            hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/screenshot.sh window"))

-- ── Screen Recording ─────────────────────────────────────────────────────
-- SUPER + SHIFT + R     -> Screen record region (wf-recorder)
hl.bind(mainMod .. " + SHIFT + R",        hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/screenrecord.sh"))

-- ── Workspaces ───────────────────────────────────────────────────────────
-- Switch workspaces with SUPER + [1-9, 0]
-- Move active window to workspace with SUPER + SHIFT + [1-9, 0]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + CTRL + S",  hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with SUPER + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with SUPER + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ── Multimedia & Laptop Hardware Keys ──────────────────────────────────────
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Media keys (playerctl)
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
