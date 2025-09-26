return {
	"daliusd/ghlite.nvim",
	config = function()
		require("ghlite").setup({
			debug = false, -- if set to true debugging information is written to ~/.ghlite.log file
			view_split = "vsplit", -- set to empty string '' to open in active buffer
			diff_split = "vsplit", -- set to empty string '' to open in active buffer
			comment_split = "split", -- set to empty string '' to open in active buffer
			open_command = "open", -- open command to use, e.g. on Linux you might want to use xdg-open
			keymaps = { -- override default keymaps with the ones you prefer
				diff = {
					open_file = "gf",
					open_file_tab = "gt",
					open_file_split = "gs",
					open_file_vsplit = "gv",
					approve = "<C-A>",
				},
				comment = {
					send_comment = "<C-CR>",
				},
				pr = {
					approve = "<C-A>",
				},
			},
		})
	end,
	keys = {
		{ "<leader>gus", ":GHLitePRSelect<cr>", silent = true, desc = "PR Select" },
		{ "<leader>guo", ":GHLitePRCheckout<cr>", silent = true, desc = "PR Checkout" },
		{ "<leader>guv", ":GHLitePRView<cr>", silent = true, desc = "PR View" },
		{ "<leader>guu", ":GHLitePRLoadComments<cr>", silent = true, desc = "PR Load Comments" },
		{ "<leader>gup", ":GHLitePRDiff<cr>", silent = true, desc = "PR Diff" },
		{ "<leader>gul", ":GHLitePRDiffview<cr>", silent = true, desc = "PR Diffview" },
		{ "<leader>gua", ":GHLitePRAddComment<cr>", silent = true, desc = "PR Add comment" },
		{
			"<leader>gua",
			":GHLitePRAddComment<cr>",
			mode = "x",
			silent = true,
			desc = "PR Add comment",
		},
		{ "<leader>guc", ":GHLitePRUpdateComment<cr>", silent = true, desc = "PR Update comment" },
		{ "<leader>gud", ":GHLitePRDeleteComment<cr>", silent = true, desc = "PR Delete comment" },
		{ "<leader>gug", ":GHLitePROpenComment<cr>", silent = true, desc = "PR Open comment" },
	},
}
