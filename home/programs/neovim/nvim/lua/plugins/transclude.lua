return {
	"matthewtapps/transclude.nvim",
	-- Local plugin (same pattern as markdown-table-wrap.nvim): source vendored
	-- under neovim/nvim/localplugins/ so it ships with the flake to every
	-- machine. Edits there need a rebuild to take effect.
	dir = vim.fn.stdpath("config") .. "/localplugins/transclude.nvim",
	ft = { "markdown", "markdown.mdx" },
	-- Renders Obsidian `![[note]]` / `![[note#Heading]]` / `![[note#^block]]`
	-- embeds as styled virtual lines below the embed (obsidian.nvim itself has
	-- this only on its 4.0 wishlist). Raw `![[...]]` is overlaid with a header
	-- except on the cursor line, so <CR> (obsidian.nvim smart action) still
	-- follows the link to the embedded file/section/block.
	opts = {},
	keys = {
		{ "<leader>me", "<cmd>Transclude toggle<cr>", desc = "Toggle embeds (transclusion)" },
	},
}
