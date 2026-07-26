-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- Noctalia lock screen uses this PAM service — must match the one with fprintAuth = true
hl.env("NOCTALIA_PAM_SERVICE", "noctalia")

----------------
---- MONITORS --
----------------

local mon1 = "desc:Tianma Microelectronics Ltd. TL145MDXP02"
local mon2 = "desc:AOC Q27G2G3R3B 137P6HA011487"

hl.monitor({ output = mon1, mode = "3072x1920@60.00Hz", position = "0x0", scale = 1.5 })
hl.monitor({ output = mon2, mode = "2560x1440@143.91Hz", position = "-2560x0", scale = 1 })

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

hl.workspace_rule({ workspace = "1", monitor = mon2, default = true })
hl.workspace_rule({ workspace = "2", monitor = mon2 })
hl.workspace_rule({ workspace = "3", monitor = mon2 })
hl.workspace_rule({ workspace = "4", monitor = mon2 })
hl.workspace_rule({ workspace = "5", monitor = mon2 })
hl.workspace_rule({ workspace = "6", monitor = mon2 })
hl.workspace_rule({ workspace = "7", monitor = mon2 })
hl.workspace_rule({ workspace = "8", monitor = mon2 })
hl.workspace_rule({ workspace = "9", monitor = mon2, on_created_empty = "ghostty -e spotify_player" })

---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_options = "ctrl:nocaps",
        kb_rules = "",

        follow_mouse = 1,

        sensitivity = 0.2, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = true,
            scroll_factor = 0.15,
            clickfinger_behavior = true,
        },
        accel_profile = "flat",
    },
})

hl.device({
    name = "glorious-model-o",
    sensitivity = -0.2,
    accel_profile = "flat",
})
