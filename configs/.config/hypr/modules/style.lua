hl.config({
    general = {
        gaps_in  = 4,
        gaps_out = 6,
        border_size = 2,
        col = {
            active_border   = { colors = {"rgba(cba6f7ee)", "rgba(89b4faff)"}, angle = 45 },
            inactive_border = "rgba(585b70aa)",
        },
        allow_tearing = true,
        layout = "dwindle",
    },

    decoration = {
        rounding       = 3,
        rounding_power = 2,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = 0.88,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled   = false,
        },
    },

    animations = {
        enabled = true,
    },

    misc = {
	force_default_wallpaper = 0,
	disable_hyprland_logo = true,
    },

    dwindle = {
        preserve_split = true, -- You probably want this
    },

    master = {
        new_status = "master",
    },

    scrolling = {
        fullscreen_on_one_column = true,
    },
})

