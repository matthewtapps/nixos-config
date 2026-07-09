return {
	"obsidian-nvim/obsidian.nvim",
	version = "*",
	-- Load for markdown so it is ready when a vault note opens, plus the vault
	-- commands. ft-gating keeps it off in code buffers.
	ft = "markdown",
	dependencies = {
		"folke/snacks.nvim", -- picker + note-search UI
	},
	---@module 'obsidian'
	---@type obsidian.config
	opts = {
		workspaces = {
			{ name = "notes", path = "~/notes" },
		},
		-- Use the unified `:Obsidian <sub>` commands only; silence the legacy
		-- camelCase (:ObsidianBacklinks) deprecation.
		legacy_commands = false,
		-- render-markdown.nvim owns rendering; disable obsidian's concealment so
		-- the two do not fight over the same buffer.
		ui = { enable = false },
		picker = { name = "snacks.pick" },
		-- [[wikilink]] / #tag completion is provided by the built-in obsidian-ls
		-- LSP now, not nvim-cmp — no completion config needed here.
	},
}
