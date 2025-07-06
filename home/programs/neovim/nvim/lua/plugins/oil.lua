-- home/programs/neovim/nvim/lua/plugins/oil.lua
return {
	"stevearc/oil.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		require("oil").setup({
			default_file_explorer = true,
			columns = {
				"icon",
			},
			buf_options = {
				buflisted = false,
				bufhidden = "hide",
			},
			win_options = {
				wrap = false,
				signcolumn = "yes",
				cursorcolumn = true,
				foldcolumn = "0",
				spell = false,
				list = false,
				conceallevel = 3,
				concealcursor = "nvic",
			},
			delete_to_trash = false,
			skip_confirm_for_simple_edits = true,
			prompt_save_on_select_new_entry = false,
			cleanup_delay_ms = 2000,
			watch_for_changes = true,
			keymaps = {
				["g?"] = "actions.show_help",
				["l"] = "actions.select",
				["<CR>"] = "actions.select",
				["<C-s>"] = "actions.select_vsplit",
				["<C-h>"] = "actions.select_split",
				["<C-t>"] = {
					desc = "Open in new tab",
					callback = function()
						local oil = require("oil")
						local entry = oil.get_cursor_entry()
						if entry and entry.type == "file" then
							local dir = oil.get_current_dir()
							local filename = dir .. entry.name
							-- Close oil
							oil.close()
							-- Open file in new WezTerm tab
							vim.fn.system('wezterm cli spawn -- nvim "' .. filename .. '"')
						-- Optionally close current nvim if you want
						-- vim.cmd('quit')
						else
							oil.select()
						end
					end,
				},
				["<C-p>"] = "actions.preview",
				["<C-c>"] = "actions.close",
				["<C-l>"] = "actions.refresh",
				["-"] = "actions.parent",
				["<BS>"] = "actions.parent",
				["_"] = "actions.open_cwd",
				["`"] = "actions.cd",
				["~"] = "actions.tcd",
				["gs"] = "actions.change_sort",
				["gx"] = "actions.open_external",
				["g."] = "actions.toggle_hidden",
				["g\\"] = "actions.toggle_trash",
				["<leader>e"] = "actions.close",
			},
			use_default_keymaps = false,
			view_options = {
				show_hidden = true,
				is_hidden_file = function(name, bufnr)
					return vim.startswith(name, ".")
				end,
				is_always_hidden = function(name, bufnr)
					return false
				end,
				sort = {
					{ "type", "asc" },
					{ "name", "asc" },
				},
			},
		})

		vim.keymap.set("n", "<leader>e", "<CMD>Oil<CR>", { desc = "Open file explorer" })
	end,
}
