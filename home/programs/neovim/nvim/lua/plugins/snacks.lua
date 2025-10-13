return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	opts = {
		terminal = { enabled = true, win = { style = "float" } },
		scroll = { enabled = false },
		animate = { enabled = false },
		notifier = { top_down = true, enabled = true },
		input = { enabled = true },
		picker = { enabled = true },
		bigfile = { enabled = true },
		scope = { enabled = true },
		quickfile = { enabled = true },
		words = { enabled = true },
		indent = { enabled = true },
		dashboard = {
			enabled = true,
			preset = {
				header = [[
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣠⣴⣶⣶⡾⠿⠿⠿⠛⠛⠛⠛⠛⣛⣛⣛⡛⠛⠛⠛⠻⠟⠟⠿⢿⠿⠿⣶⣶⣶⣤⣄⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢀⣤⣾⡿⠟⠛⠉⠀⣀⣀⣠⣤⣤⣤⣤⣦⣾⣿⡿⠿⠿⠿⠿⠿⠿⢿⣿⣿⣶⣤⣍⣉⣙⣛⠳⠭⡛⠻⢿⡶⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢸⣏⢿⣀⣤⣶⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣿⣶⣤⣤⣄⡀⠀⠘⠋⢛⣻⣿⠟⠲⢶⣤⣠⡿⣸⡆⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢸⠉⠓⠿⣿⣿⣿⣿⣿⣿⣿⡿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢿⢟⠛⠁⠀⠀⠀⣀⣠⣽⣷⣶⣾⣿⠟⠛⢹⣅⣤⣤⢦⣦⣤⣄⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢸⡄⡀⠀⠀⠀⠉⠉⠛⠛⠻⠿⠿⠿⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⠿⡿⡿⣿⣛⣛⣭⠭⠷⠀⢀⠀⣸⠁⠈⠙⣏⠉⠹⡿⡷⡄
⠀⠀⠀⠀⠀⠀⠀⢸⡇⢧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠈⠀⣀⠀⠀⠀⠒⠒⠒⠚⠛⣯⣁⣈⣅⡤⡤⠀⡇⢸⢀⢻⠶⠞⠛⠋⠙⣧⢱⠻⣷
⠀⠀⠀⠀⠀⠀⠀⢸⣷⢸⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⠻⢭⣉⠉⠉⠉⠉⣯⣀⣸⣆⡇⢀⠇⡌⣸⣾⠀⠀⠀⠀⠀⣏⢸⠀⣿
⠀⠀⠀⠀⠀⠀⠀⠀⣿⡘⡀⢇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢳⡀⠈⠉⠉⣏⠙⡇⠃⣸⢰⢇⣿⡇⠀⠀⠀⠀⢠⣏⣿⢇⡇
⠀⠀⠀⠀⠀⠀⠀⠀⠹⡇⣇⢸⡄⢠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠹⡄⠀⠒⢿⠒⠛⢰⠇⡾⢸⣹⠃⠀⠀⠀⢠⡟⢈⣾⡿⠁
⠀⠀⠀⠀⠀⠀⠀⠀⠀⢷⣸⡄⢧⠈⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⠈⠀⢀⡟⢰⢃⣆⡟⠀⠀⢀⡴⠋⣠⣯⡾⠁⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣧⢣⠘⡆⠸⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡇⠀⠀⠀⢠⡞⢠⢏⡾⣿⣁⣠⠾⠋⣠⢼⣷⠟⠀⠀⠀
⠀⠀⠀⠀⠀⣀⣤⡤⠶⠛⢻⣿⣧⠹⡄⢳⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡾⠀⠀⢀⣠⠏⢠⢏⡽⣼⠟⠉⣠⣴⣿⡷⠛⠁⠀⠀⠀⠀
⠀⠀⣠⡴⠻⠉⣡⣤⠶⠚⠛⢹⣎⢆⠱⡄⢳⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣼⣿⡖⣲⡞⠓⣰⢯⣟⣰⣏⣠⡤⣿⣿⡙⠛⠶⣄⠀⠀⠀⠀
⢰⡿⠃⢠⡾⠋⠁⠀⠀⠀⠀⠀⠹⣮⡁⠙⢆⠓⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣿⡿⣏⡽⠋⠁⣼⣿⣫⡾⠋⠩⡀⢢⠀⠈⡝⢷⡄⢺⢷⡆⠀⠀
⢹⣇⣀⠸⣷⡀⠀⠀⣀⠀⠀⠀⠀⠈⠳⣄⡈⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣠⣿⣛⣩⣿⠯⠅⠀⣠⣿⡿⠋⠀⢀⣠⠏⣠⠇⢀⣼⣴⠇⣸⣸⡏⠀⠀
⠀⠙⢷⣄⡺⣟⣦⣤⣐⡿⢿⣲⣤⣤⣀⡈⠙⠳⢤⣄⣀⣀⡀⠀⠀⠀⢀⣠⣤⠬⢤⣤⣬⠥⠄⣀⣀⡬⠞⠋⠀⠀⣠⣤⣶⣿⣥⣾⠿⣟⣥⣻⡿⠋⠀⠀⠀
⠀⠀⠀⠈⠛⠳⢯⣵⣛⣿⠿⢷⣾⣯⡭⠿⣶⣶⣤⣀⣉⣉⣉⣛⣛⣛⣛⠛⡛⣛⣛⣛⣛⣋⣩⣉⣁⣶⣶⠶⠮⠭⠟⠛⢛⣉⣉⣬⣷⠟⠛⠁⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠈⠙⠾⣭⣙⠓⠛⠿⠧⣤⣤⣤⣌⣉⣉⣩⣻⣛⠛⠉⠉⠭⠭⠭⢭⣭⣿⣽⣯⣍⣁⣤⣤⣤⣤⡶⣶⣾⣿⣽⠿⠛⠁⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠓⠶⠶⠤⣤⣀⣀⣀⣮⣍⣭⢭⣉⣉⣉⣉⣉⠉⣉⢉⢉⣉⣓⣀⣀⣹⣩⠭⠿⠷⠛⠋⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
        ]],
				keys = {
					{ icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.picker.files()" },
					{ icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
					{ icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.picker.grep()" },
					{ icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.picker.recent()" },
					{ icon = " ", key = "s", desc = "Restore Session", action = ":SessionLoad" },
					{ icon = " ", key = "q", desc = "Quit", action = ":qa" },
				},
			},
		},
	},
	keys = {
		{
			"<leader><space>",
			function()
				Snacks.picker.smart()
			end,
			desc = "Smart Find Files",
		},
		{
			"<leader>/",
			function()
				Snacks.picker.grep()
			end,
			desc = "Grep",
		},
		{
			"<leader>n",
			function()
				Snacks.picker.notifications()
			end,
			desc = "Notification History",
		},
		{
			"<leader>:",
			function()
				Snacks.picker.command_history()
			end,
			desc = "Command History",
		},
		{
			"<leader>fr",
			function()
				Snacks.picker.recent()
			end,
			desc = "Recent",
		},
		{
			"<leader>un",
			function()
				Snacks.notifier.hide()
			end,
			desc = "Dismiss All Notifications",
		},
		{
			"<leader>gg",
			function()
				Snacks.lazygit()
			end,
			desc = "Lazygit",
		},
		{
			"<leader>gB",
			function()
				Snacks.gitbrowse()
			end,
			desc = "Git Browse",
			mode = { "n", "v" },
		},
		{
			"<leader>cR",
			function()
				Snacks.rename.rename_file()
			end,
			desc = "Rename File",
		},
		-- LSP
		{
			"gd",
			function()
				Snacks.picker.lsp_definitions()
			end,
			desc = "Goto Definition",
		},
		{
			"gD",
			function()
				Snacks.picker.lsp_declarations()
			end,
			desc = "Goto Declaration",
		},
		{
			"gr",
			function()
				Snacks.picker.lsp_references()
			end,
			nowait = true,
			desc = "References",
		},
		{
			"gI",
			function()
				Snacks.picker.lsp_implementations()
			end,
			desc = "Goto Implementation",
		},
		{
			"gy",
			function()
				Snacks.picker.lsp_type_definitions()
			end,
			desc = "Goto T[y]pe Definition",
		},
		{
			"<leader>ss",
			function()
				Snacks.picker.lsp_symbols()
			end,
			desc = "LSP Symbols",
		},
		{
			"<leader>sS",
			function()
				Snacks.picker.lsp_workspace_symbols()
			end,
			desc = "LSP Workspace Symbols",
		},
		{
			"<C-/>",
			mode = { "n", "t" },
			function()
				Snacks.terminal()
			end,
			desc = "Toggle terminal",
		},
		{
			"<leader>.",
			function()
				Snacks.scratch()
			end,
			desc = "Toggle Scratch Buffer",
		},
		{
			"<leader>S",
			function()
				Snacks.scratch.select()
			end,
			desc = "Select Scratch Buffer",
		},
		{
			"gd",
			function()
				Snacks.picker.lsp_definitions()
			end,
			desc = "Goto Definition",
		},
	},
}
