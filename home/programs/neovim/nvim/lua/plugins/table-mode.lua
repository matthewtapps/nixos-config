return {
	"dhruvasagar/vim-table-mode",
	ft = { "markdown", "markdown.mdx" },
	init = function()
		-- Use markdown-style corners (|) instead of the default (+) so the
		-- separator row is written as |---|---| rather than +---+---+.
		vim.g.table_mode_corner = "|"
		-- Default prefix is <leader>t, which neotest owns; park table-mode under
		-- <leader>m with the markdown-table-wrap maps instead.
		vim.g.table_mode_map_prefix = "<Leader>m"
		vim.g.table_mode_toggle_map = "m"
		vim.g.table_mode_realign_map = "<Leader>mr"
	end,
	-- Handy while editing the player-sheet tables:
	--   :TableModeToggle   (<leader>mm)  auto-align pipes as you type
	--   :TableModeRealign  (<leader>mr)  re-align the table under the cursor
}
