local config = {}
local wezterm = require("wezterm")

config.color_scheme = "Everforest Dark Medium (Gogh)"
config.font = wezterm.font("GeistMono Nerd Font")
config.enable_tab_bar = true
config.window_padding = {
	left = "0px",
	right = "0px",
	top = "0px",
	bottom = "0.25cell",
}
enable_scroll_bar = false
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = true
config.leader = { key = " ", mods = "SHIFT", timeout_milliseconds = 1000 }

config.keys = {
	{ key = "h", mods = "CTRL", action = wezterm.action.ActivatePaneDirection("Left") },
	{ key = "j", mods = "CTRL", action = wezterm.action.ActivatePaneDirection("Down") },
	{ key = "k", mods = "CTRL", action = wezterm.action.ActivatePaneDirection("Up") },
	{ key = "l", mods = "CTRL", action = wezterm.action.ActivatePaneDirection("Right") },

	-- Tab navigation with Shift+hl
	{ key = "h", mods = "CTRL|SHIFT", action = wezterm.action.ActivateTabRelative(-1) },
	{ key = "l", mods = "CTRL|SHIFT", action = wezterm.action.ActivateTabRelative(1) },

	-- Pane splitting
	{ key = "|", mods = "LEADER|SHIFT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "-", mods = "LEADER", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },

	-- Close pane
	{ key = "q", mods = "LEADER", action = wezterm.action.CloseCurrentPane({ confirm = false }) },

	-- Create new tab
	{ key = "c", mods = "LEADER", action = wezterm.action.SpawnTab("CurrentPaneDomain") },

	-- Close current tab
	{ key = "d", mods = "LEADER", action = wezterm.action.CloseCurrentTab({ confirm = false }) },

	-- Rename tab
	{
		key = ",",
		mods = "LEADER",
		action = wezterm.action.PromptInputLine({
			description = "Enter new name for tab",
			action = wezterm.action_callback(function(window, pane, line)
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},

	-- Toggle pane zoom
	{ key = "z", mods = "LEADER", action = wezterm.action.TogglePaneZoomState },

	-- Show tab navigator
	{ key = "w", mods = "LEADER", action = wezterm.action.ShowTabNavigator },

	-- Show launcher menu (for quick commands)
	{ key = "p", mods = "LEADER", action = wezterm.action.ShowLauncher },

	-- Copy mode
	{ key = "[", mods = "LEADER", action = wezterm.action.ActivateCopyMode },

	-- Paste
	{ key = "]", mods = "LEADER", action = wezterm.action.PasteFrom("Clipboard") },
}

for i = 1, 9 do
	table.insert(config.keys, {
		key = tostring(i),
		mods = "LEADER",
		action = wezterm.action.ActivateTab(i - 1),
	})
end

config.scrollback_lines = 10000

config.selection_word_boundary = " \t\n{}[]()\"'`,;:@"

config.enable_kitty_keyboard = true

return config
