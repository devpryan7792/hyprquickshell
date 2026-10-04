-- window-rules.lua
-- Window rules and layer rules

-- Ignore maximize requests from all apps
hl.window_rule({
    name           = "suppress-maximize-events",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix dragging issues with XWayland
hl.window_rule({
    name     = "fix-xwayland-drags",
    match    = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Hyprland-run launcher window rule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})

-- Quickshell Layer Rules (Blur and Ignore Alpha)
hl.layer_rule({
    name = "quickshell-blur",
    match = { namespace = "^quickshell$" },
    blur = true,
    ignore_alpha = 0.2,
})

-- Seamless borderless terminals (Ghostty, Kitty, Foot, Alacritty)
hl.window_rule({
    name = "terminal-seamless",
    match = { class = "^(com\\.mitchellh\\.ghostty|ghostty|kitty|foot|Alacritty)$" },
    border_size = 0,
})

-- Smart borders: No border when only one tiled window is on the workspace
hl.window_rule({
    name = "no-border-when-only",
    match = { float = false, workspace = "w[tv1]" },
    border_size = 0,
})

-- No border when fullscreen / monocle
hl.window_rule({
    name = "no-border-fullscreen",
    match = { float = false, workspace = "f[1]" },
    border_size = 0,
})

-- Scratchpad Floating Terminal (Seamless, centered, auto-placed in special:scratchpad)
hl.window_rule({
    name = "scratchpad-term",
    match = { initial_title = "^Scratchpad$" },
    workspace = "special:scratchpad",
    float = true,
    size = "960 580",
    center = true,
    border_size = 0,
})

