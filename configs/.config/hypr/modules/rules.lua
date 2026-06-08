suppressMaximizeRule = hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- "Smart gaps" / "No gaps when only"
 hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
 hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
 hl.window_rule({
     name  = "no-gaps-wtv1",
     match = { float = false, workspace = "w[tv1]" },
     border_size = 0,
     rounding    = 0,
 })
 hl.window_rule({
     name  = "no-gaps-f1",
     match = { float = false, workspace = "f[1]" },
     border_size = 0,
     rounding    = 0,
 })

-- Regla para Apps de Steam
hl.window_rule({
    immediate = true,
    fullscreen = true,
    match = { class = "^steam_app_d+$" }
})

-- Regla para Picture-in-Picture
hl.window_rule({
    float = true,
    move = "1280 720",
    size = "480 270",
    keep_aspect_ratio = true,
    match = { title = "^Picture-in-Picture$" }
})

-- Regla Powermenu
hl.window_rule({
    float = true,
    fullscreen = true,
    border_size = 0,
    no_anim = true,
    stay_focused = true,
    match = { title = "^quickshell-powermenu$" }
})
