return {
	"dhruvasagar/vim-table-mode",
	ft = { "markdown", "markdown.mdx" },
	init = function()
		-- Use markdown-style corners (|) instead of the default (+) so the
		-- separator row is written as |---|---| rather than +---+---+.
		vim.g.table_mode_corner = "|"
	end,
	-- Handy while editing the player-sheet tables:
	--   :TableModeToggle   (<leader>tm)  auto-align pipes as you type
	--   :TableModeRealign  (<leader>tr)  re-align the table under the cursor
}
