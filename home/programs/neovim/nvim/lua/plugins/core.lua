-- home/programs/neovim/nvim/lua/plugins/core.lua
return {
	-- Colorscheme
	{
		"neanias/everforest-nvim",
		priority = 1000,
		lazy = false,
		version = false,
		config = function()
			vim.cmd([[colorscheme everforest]])
			require("everforest").setup({
				background = "soft",
				transparent_background_level = 0,
				italics = true,
				disable_italic_comments = true,
				sign_column_background = "none",
				ui_contrast = "low",
				dim_inactive_windows = false,
				diagnostic_text_highlight = true,
				diagnostic_virtual_text = "coloured",
				diagnostic_line_highlight = true,
				spell_foreground = false,
				inlay_hints_background = "dimmed",
				show_eob = false,
				float_style = "bright",
				on_highlights = function(hl, palette)
					hl.NeoTreeNormal = { bg = palette.bg1 }
					hl.NeoTreeNormalNC = { bg = palette.bg1 }
					hl.NeoTreeEndOfBuffer = { bg = palette.bg1 }
				end,
			})
		end,
	},

	-- Essential utilities
	{ "nvim-lua/plenary.nvim" },
	{ "nvim-tree/nvim-web-devicons" },

	-- Comments
	{
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
	},

	-- Autopairs
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = function()
			require("nvim-autopairs").setup({})
		end,
	},

	-- Git signs
	{
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup()
		end,
	},
}
