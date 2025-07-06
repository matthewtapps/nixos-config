-- home/programs/neovim/nvim/lua/plugins/telescope.lua
return {
	"nvim-telescope/telescope.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope-fzf-native.nvim",
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")
		local action_state = require("telescope.actions.state")

		-- Custom action to open in new WezTerm tab
		local open_in_new_tab = function(prompt_bufnr)
			local selection = action_state.get_selected_entry()
			actions.close(prompt_bufnr)
			if selection then
				local filename = selection.filename or selection.value
				vim.fn.system('wezterm cli spawn -- nvim "' .. filename .. '"')
			end
		end

		telescope.setup({
			defaults = {
				mappings = {
					i = {
						["<C-t>"] = open_in_new_tab,
						["<C-j>"] = actions.move_selection_next,
						["<C-k>"] = actions.move_selection_previous,
						["<CR>"] = actions.select_default,
						["<C-x>"] = actions.select_horizontal,
						["<C-v>"] = actions.select_vertical,
						["<C-c>"] = actions.close,
						["<Esc>"] = actions.close,
					},
					n = {
						["<C-t>"] = open_in_new_tab,
						["<CR>"] = actions.select_default,
						["<C-x>"] = actions.select_horizontal,
						["<C-v>"] = actions.select_vertical,
						["<C-c>"] = actions.close,
						["<Esc>"] = actions.close,
					},
				},
			},
		})

		-- Keymaps
		vim.keymap.set("n", "<leader><leader>", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
		vim.keymap.set("n", "<leader>/", "<cmd>Telescope live_grep<cr>", { desc = "Grep search" })
		vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Find buffers" })
		vim.keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", { desc = "Find help" })
		vim.keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Recent files" })
	end,
}
