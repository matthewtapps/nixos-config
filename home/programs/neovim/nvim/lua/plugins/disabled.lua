-- home/programs/neovim/nvim/lua/plugins/disabled.lua
return {
	{ "williamboman/mason.nvim", enabled = false },
	{ "lukas-reineke/indent-blankline.nvim", enabled = false },
	{ "catppuccin/nvim", enabled = false },
	{ "neo-tree.nvim", enabled = false }, -- Remove neo-tree since we're using oil
	{ "folke/flash.nvim", enabled = false },
	{ "folke/which-key.nvim", enabled = false },
	{ "folke/noice.nvim", enabled = false },
	{ "rcarriga/nvim-notify", enabled = false },
	{ "nvim-pack/nvim-spectre", enabled = false },
	{ "folke/todo-comments.nvim", enabled = false },
	{ "folke/trouble.nvim", enabled = false },
	-- Keep snacks but disable terminal functionality
}
