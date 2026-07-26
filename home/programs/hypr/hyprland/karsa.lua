----------------
---- MONITORS --
----------------

-- local mon1 = "desc:Samsung Electric Company C27JG5x HTOM800138"
local mon1 = "desc:AOC Q27G2G3R3B 137P6HA011487"

-- hl.monitor({ output = mon1, mode = "2560x1440@144.00Hz", position = "0x0", scale = 1 })
hl.monitor({ output = mon1, mode = "2560x1440@165.00Hz", position = "0x0", scale = 1 })

-- hl.env("LIBVA_DRIVER_NAME", "nvidia")
-- hl.env("GBM_BACKEND", "nvidia-drm")
-- hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
-- hl.env("NVD_BACKEND", "direct")

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

hl.workspace_rule({ workspace = "1", monitor = mon1, default = true }) -- on_created_empty = "slack --enable-features=UseOzonePlatform --ozone-platform=wayland"
hl.workspace_rule({ workspace = "2", monitor = mon1 })
hl.workspace_rule({ workspace = "3", monitor = mon1 })
hl.workspace_rule({ workspace = "4", monitor = mon1 })
-- hl.workspace_rule({ workspace = "5", monitor = mon2, default = true })
-- hl.workspace_rule({ workspace = "6", monitor = mon2 })
-- hl.workspace_rule({ workspace = "7", monitor = mon2 })
hl.workspace_rule({ workspace = "8", monitor = mon1 })
hl.workspace_rule({ workspace = "9", monitor = mon1, on_created_empty = "ghostty -e spotify_player" })

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

        accel_profile = "flat",
    },

    opengl = {
        nvidia_anti_flicker = false,
    },

    debug = {
        damage_tracking = 0,
    },
})

hl.device({
    name = "glorious-model-o",
    sensitivity = -0.2,
    accel_profile = "flat",
})
