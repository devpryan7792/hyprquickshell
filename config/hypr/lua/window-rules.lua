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

-- Quake-Style Dropdown Terminal (SUPER + `)
hl.window_rule({
    name      = "dropdown-terminal",
    match     = { initial_title = "^dropdown-terminal$" },
    workspace = "special:dropdown",
    float     = true,
    size      = "75% 55%",
    move      = "12.5% 2%",
})

-- Quickshell Layer Rules (Blur and Ignore Alpha)
hl.layer_rule({
    name = "quickshell-blur",
    match = { namespace = "^quickshell$" },
    blur = true,
    ignore_alpha = 0.2,
})

