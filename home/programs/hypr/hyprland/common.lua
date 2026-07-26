---------------------
---- MY PROGRAMS ----
---------------------

local terminal = "ghostty"
local fileManager = "thunar"
local menu = "noctalia-shell ipc call launcher toggle"

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("noctalia-shell")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- hl.env("QT_QPA_PLATFORM", "wayland;xcb")
-- hl.env("GDK_BACKEND", "wayland,ags,x11,*")
-- hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("HYPRSHOT_DIR", "screenshots/")

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in = 20,
        gaps_out = 40,
        no_focus_fallback = true,

        border_size = 0,

        -- col = {
        --     active_border   = "rgb(a9b665)",
        --     inactive_border = "rgb(665c54)",
        -- },

        resize_on_border = false,

        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding = 0,

        active_opacity = 0.99,
        inactive_opacity = 0.95,
    },

    dwindle = {
        preserve_split = true, -- You probably want this
    },

    misc = {
        force_default_wallpaper = 0, -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo = true, -- If true disables the random hyprland logo / anime girl background. :(
        disable_splash_rendering = true,
        focus_on_activate = false,
        middle_click_paste = false,
    },

    -- cursor = {
    --     no_hardware_cursors = true,
    -- },
})

---------------------
---- KEYBINDINGS ----
---------------------

-- The Lua API matches modifier names exactly; only ALT/MOD1 (not LALT) is
-- recognised. The old .conf parser matched substrings, so "LALT" there was
-- always just plain ALT anyway -- this is the same binding, not a change.
local mainMod = "ALT"

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + SHIFT + SPACE", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo()) -- dwindle
hl.bind("SUPER + L", hl.dsp.exec_cmd("noctalia-shell ipc call lockScreen lock"))
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind("SUPER + SHIFT + A", hl.dsp.exec_cmd("record-region-toggle"))
hl.bind(mainMod .. " + X", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("noctalia-shell ipc call controlCenter toggle"))
hl.bind("SUPER + V", hl.dsp.exec_cmd("noctalia-shell ipc call launcher clipboard"))

-- Keybind cheatsheet (hold f/j + `/`, or + shift+`/` = "?"). kanata emits
-- ctrl+alt(+shift)+slash from the herdr layer; both open the floating sheet.
hl.bind("CTRL + ALT + slash", hl.dsp.exec_cmd("keybind-cheatsheet toggle"))
hl.bind("CTRL + ALT + SHIFT + slash", hl.dsp.exec_cmd("keybind-cheatsheet toggle"))

-- Sound
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +1%"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -1%"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("pactl set-source-mute @DEFAULT_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, repeating = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true, repeating = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "d" }))

hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "d" }))

hl.bind(mainMod .. " + SHIFT + h", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + l", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + k", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + j", hl.dsp.window.move({ direction = "d" }))

hl.bind(mainMod .. " + a", hl.dsp.workspace.move({ monitor = "+1" }))
hl.bind(mainMod .. " + f", hl.dsp.workspace.move({ monitor = "-1" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
-- `drag = true` is the bindm equivalent; the `mouse` key the upstream sample
-- config uses is not a real BindOptions field and is silently ignored.
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { drag = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { drag = true })

-- Lid switch handling
hl.bind("switch:on:Lid Switch", hl.dsp.dpms({ action = "off" }), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.dpms({ action = "on" }), { locked = true })

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- Volume Control / Pavucontrol
hl.window_rule({
    match = { class = "org.pulseaudio.pavucontrol" },
    float = true,
    size = { 600, 527 },
    move = { "monitor_w-window_w-40", 75 },
})

-- Thunar
hl.window_rule({
    match = { title = ".*Thunar" },
    float = true,
    size = { 1100, 700 },
    move = { "monitor_w-window_w-100", "monitor_h-window_w-100" },
})

-- Network Editor
hl.window_rule({
    match = { class = "nm-connection-editor" },
    float = true,
    size = { 600, 700 },
    move = { "monitor_w-window_w-40", 75 },
})

-- Overskride (Bluetooth)
hl.window_rule({
    match = { class = "io.github.kaii_lb.Overskride" },
    float = true,
    size = { 1000, 1200 },
    move = { "monitor_w-window_w-40", 75 },
})

-- Btop
hl.window_rule({
    match = { class = "ghostty-btop" },
    float = true,
    size = { 1000, 800 },
})

-- Keybind cheatsheet
hl.window_rule({
    match = { class = "cheatsheet" },
    float = true,
    size = { 900, 950 },
    center = true,
})

-- GCS
hl.window_rule({
    match = { class = "GCS" },
    float = false,
})
hl.window_rule({
    match = { class = "GLFW-Application" },
    float = true,
    size = { 600, 1000 },
})

-- TUI Combat Tracker
hl.window_rule({
    match = { class = "gurps-combat-tracker", title = "Import.*" },
    float = true,
})

-- JMeter and DataGrip popup windows
hl.window_rule({
    match = { class = "Apache JMeter", title = "win.*" },
    float = true,
    no_focus = true,
})
hl.window_rule({
    match = { class = "jetbrains-datagrip", title = "win.*" },
    float = true,
    no_focus = true,
})

-- Zathura PDF viewer
hl.window_rule({
    match = { class = "org.pwmt.zathura" },
    float = true,
    size = { 1000, 1100 },
    center = true,
})

-- YouTube in Zen Browser - full opacity
hl.window_rule({
    match = { title = ".*(YouTube).*(Zen).*" },
    opacity = "1 override",
})

-- -----------------------------------------------------
-- ▄▀█ █▄░█ █ █▀▄▀█ ▄▀█ ▀█▀ █ █▀█ █▄░█
-- █▀█ █░▀█ █ █░▀░█ █▀█ ░█░ █ █▄█ █░▀█
--
-- name "Optimized"
-- -----------------------------------------------------

hl.config({
    animations = {
        enabled = true,
    },
})

hl.curve("wind", { type = "bezier", points = { { 0.05, 0.85 }, { 0.03, 0.97 } } })
hl.curve("winIn", { type = "bezier", points = { { 0.07, 0.88 }, { 0.04, 0.99 } } })
hl.curve("winOut", { type = "bezier", points = { { 0.20, -0.15 }, { 0, 1 } } })
hl.curve("liner", { type = "bezier", points = { { 1, 1 }, { 1, 1 } } })
hl.curve("md3_standard", { type = "bezier", points = { { 0.12, 0 }, { 0, 1 } } })
hl.curve("md3_decel", { type = "bezier", points = { { 0.05, 0.80 }, { 0.10, 0.97 } } })
hl.curve("md3_accel", { type = "bezier", points = { { 0.20, 0 }, { 0.80, 0.08 } } })
hl.curve("overshot", { type = "bezier", points = { { 0.05, 0.85 }, { 0.07, 1.04 } } })
hl.curve("crazyshot", { type = "bezier", points = { { 0.1, 1.22 }, { 0.68, 0.98 } } })
hl.curve("hyprnostretch", { type = "bezier", points = { { 0.05, 0.82 }, { 0.03, 0.94 } } })
hl.curve("menu_decel", { type = "bezier", points = { { 0.05, 0.82 }, { 0, 1 } } })
hl.curve("menu_accel", { type = "bezier", points = { { 0.20, 0 }, { 0.82, 0.10 } } })
hl.curve("easeInOutCirc", { type = "bezier", points = { { 0.75, 0 }, { 0.15, 1 } } })
hl.curve("easeOutCirc", { type = "bezier", points = { { 0, 0.48 }, { 0.38, 1 } } })
hl.curve("easeOutExpo", { type = "bezier", points = { { 0.10, 0.94 }, { 0.23, 0.98 } } })
hl.curve("softAcDecel", { type = "bezier", points = { { 0.20, 0.20 }, { 0.15, 1 } } })
hl.curve("md2", { type = "bezier", points = { { 0.30, 0 }, { 0.15, 1 } } })

hl.curve("OutBack", { type = "bezier", points = { { 0.28, 1.40 }, { 0.58, 1 } } })
hl.curve("easeInOutCirc", { type = "bezier", points = { { 0.78, 0 }, { 0.15, 1 } } })

hl.animation({ leaf = "border", enabled = true, speed = 1.6, bezier = "liner" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 82, bezier = "liner", style = "loop" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3.2, bezier = "winIn", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.8, bezier = "easeOutCirc" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3.0, bezier = "wind", style = "slide" })
hl.animation({ leaf = "fade", enabled = true, speed = 1.8, bezier = "md3_decel" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 1.8, bezier = "menu_decel", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "menu_accel" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.6, bezier = "menu_decel" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.8, bezier = "menu_accel" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4.0, bezier = "menu_decel", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 2.3, bezier = "md3_decel", style = "slidefadevert 15%" })
