return {
	"matthewtapps/transclude.nvim",
	-- Local plugin (same pattern as markdown-table-wrap.nvim): the checkout is
	-- authoritative, edits go live on nvim restart, no rebuild needed.
	dir = "/home/matt/dev/transclude.nvim",
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
