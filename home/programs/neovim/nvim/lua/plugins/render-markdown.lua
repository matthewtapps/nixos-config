return {
	"MeanderingProgrammer/render-markdown.nvim",
	ft = { "markdown", "markdown.mdx" },
	-- nvim-treesitter (with the markdown / markdown_inline parsers) is provided by
	-- Nix in home/programs/neovim/default.nix, so it is intentionally NOT declared
	-- as a lazy dependency here (doing so would make lazy fetch a second copy).
	---@module 'render-markdown'
	---@type render.md.UserConfig
	opts = {
		-- Keep the rendered view up even while typing; only the line under the
		-- cursor drops back to raw markdown so you can edit it.
		anti_conceal = { enabled = true },
		-- Custom callouts that mirror the pdf-gen sheet.css blocks. `note` is a
		-- built-in callout already; `play` (action/maneuver blocks) is ours. The
		-- pandoc callouts.lua filter turns these `> [!play]` / `> [!note]`
		-- blockquotes into <div class="play"> / <div class="note"> for the PDF.
		callout = {
			play = {
				raw = "[!play]",
				rendered = "󰐊 Play",
				highlight = "RenderMarkdownSuccess",
				category = "obsidian",
			},
		},
	},
}
