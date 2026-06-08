hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "intl",
        follow_mouse = 1,
        sensitivity = 0,
	force_no_accel = true,
        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})
