----------------
---- MONITORS --
----------------

local mon1 = "desc:Samsung Electric Company SAMSUNG 0x01000E00"

hl.monitor({ output = mon1, mode = "2560x1440@59.95Hz", position = "0x0", scale = 2 })

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

hl.workspace_rule({ workspace = "1", monitor = mon1, default = true })
hl.workspace_rule({ workspace = "2", monitor = mon1 })
hl.workspace_rule({ workspace = "3", monitor = mon1 })
hl.workspace_rule({ workspace = "4", monitor = mon1 })
hl.workspace_rule({ workspace = "5", monitor = mon1 })
hl.workspace_rule({ workspace = "6", monitor = mon1 })
hl.workspace_rule({ workspace = "7", monitor = mon1 })
hl.workspace_rule({ workspace = "8", monitor = mon1 })
hl.workspace_rule({ workspace = "9", monitor = mon1 })

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

        natural_scroll = true,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.
        accel_profile = "flat",
    },
})
