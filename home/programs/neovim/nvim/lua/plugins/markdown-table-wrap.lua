return {
	"matthewtapps/markdown-table-wrap.nvim",
	-- Private fork (upstream: ice345) adding focus-mode table editing. The
	-- source is vendored in this repo under neovim/nvim/localplugins/ so every
	-- machine gets it from the flake; that copy is authoritative. Edits need a
	-- `home-manager switch` (or nixos-rebuild) before nvim sees them, since the
	-- config tree is symlinked read-only out of the Nix store. Mirror to
	-- github.com/matthewtapps/markdown-table-wrap.nvim when publishing.
	dir = vim.fn.stdpath("config") .. "/localplugins/markdown-table-wrap.nvim",
	ft = { "markdown", "markdown.mdx" },
	-- View-only overlay renderer for pipe tables: wraps long cell content to fit
	-- the window without touching the buffer. render-markdown.nvim's own table
	-- renderer is disabled (see render-markdown.lua) so this plugin owns tables;
	-- vim-table-mode still handles source-level alignment when editing.
	opts = {
		highlight_preset = "render_markdown",
		pipe_table = {
			enabled = false,
		},
		auto_preview = true,
		-- Hide the table's source lines with `conceal_lines` and draw the table as
		-- one virt_lines block, rather than overlaying virt_text on the source
		-- lines. The old overlay needed 'nowrap' on the whole window — Neovim
		-- wraps a line by its RAW character count regardless of conceal, so 200+
		-- char table rows blew out to 3-4 screen rows each — and that killed the
		-- prose soft-wrap from autocmds.lua for every note containing a table.
		-- Zero-height source lines need no such thing.
		inline_conceal_lines = true,
		-- Seamless focus: landing on a table auto-enters the rendered view for
		-- native navigation; j/k past the edges sail out, <Esc> drops to raw
		-- source until the cursor leaves the table.
		auto_focus = true,
	},
	keys = {
		{ "<leader>mt", "<cmd>MarkdownTableTogglePreview<cr>", desc = "Toggle table preview" },
		{ "<leader>mp", "<cmd>MarkdownTablePreview<cr>", desc = "Preview table inline" },
		{ "<leader>mf", "<cmd>MarkdownTableFloatPreview<cr>", desc = "Preview table in float" },
		{ "<leader>mc", "<cmd>MarkdownTableCreate<cr>", desc = "Create table here" },
		-- Cell navigation moves the real cursor in the hidden source lines, so
		-- hop to the target cell first, then `i` (clear_on_insert reveals the
		-- source) to edit exactly where you landed.
		{ "]c", "<cmd>MarkdownTableNextCell<cr>", desc = "Next table cell" },
		{ "[c", "<cmd>MarkdownTablePrevCell<cr>", desc = "Prev table cell" },
		{ "]r", "<cmd>MarkdownTableNextRow<cr>", desc = "Next table row" },
		{ "[r", "<cmd>MarkdownTablePrevRow<cr>", desc = "Prev table row" },
	},
	config = function(_, opts)
		require("markdown-table-wrap").setup(opts)
		-- No <CR>-to-focus map: auto_focus enters tables on cursor arrival, and
		-- obsidian.nvim owns <CR> in markdown buffers (smart_action/checkboxes).

		-- The overlay draws the whole table as virtual text, so the real cursor
		-- (parked in the concealed source lines) gives no visual cue which cell
		-- it is in. Echo "row · column ▸ cell text" from the hidden source line
		-- whenever the cursor sits inside a table, so ]c/[c/]r/[r navigation has
		-- feedback without dropping the rendered view.
		local function cell_indicator()
			-- Exact match, not a prefix: the focus float's buffer is filetype
			-- "markdown-table-wrap", which "^markdown" also matches. This would then
			-- run against the float's rendered buffer as though it were the document
			-- — echoing on every cursor move inside a table, off the wrong lines.
			local ft = vim.bo.filetype
			if ft ~= "markdown" and ft ~= "markdown.mdx" then
				return
			end
			local parser = require("markdown-table-wrap.parser")
			local nav = require("markdown-table-wrap.nav")
			local bufnr = vim.api.nvim_get_current_buf()
			local lnum, col = unpack(vim.api.nvim_win_get_cursor(0))
			local info = parser.parse_at_cursor(bufnr, lnum)
			if not info then
				if vim.b.mtw_cell_echoed then
					vim.b.mtw_cell_echoed = nil
					vim.api.nvim_echo({ { "", "" } }, false, {})
				end
				return
			end
			local line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
			local spans = nav.spans(line)
			local index
			for i, span in ipairs(spans) do
				if col >= span.start_col and col <= span.end_col then
					index = i
					break
				end
			end
			index = index or #spans
			local span = spans[index]
			if not span then
				return
			end
			-- Header cells are parse_inline() results ({ text, spans }), not strings.
			local header_cell = info.header[index]
			local header = vim.trim(type(header_cell) == "table" and header_cell.text or header_cell or ("col " .. index))
			local text = vim.trim(line:sub(span.start_col + 1, span.end_col))
			local where = lnum <= info.separator_lnum and "header" or ("row %d"):format(lnum - info.separator_lnum)
			local prefix = ("%s · %s"):format(where, header)

			-- Budget the WHOLE message against v:echospace — the columns available
			-- before Neovim decides a message needs its own line and stops with
			-- "Press ENTER". Capping the cell text alone at 60 still overflows a
			-- narrow split once the row/header prefix is added, which made entering
			-- a table with a long cell hit that prompt on every keypress.
			local budget = (vim.v.echospace or vim.o.columns) - vim.fn.strdisplaywidth(prefix) - 3
			if budget < 1 then
				text = ""
			elseif vim.fn.strdisplaywidth(text) > budget then
				text = vim.fn.strcharpart(text, 0, math.max(1, budget - 1)) .. "…"
			end

			vim.b.mtw_cell_echoed = true
			vim.api.nvim_echo({
				{ prefix, "Title" },
				{ text ~= "" and (" ▸ " .. text) or "", "Normal" },
			}, false, {})
		end

		vim.api.nvim_create_autocmd("CursorMoved", {
			group = vim.api.nvim_create_augroup("MarkdownTableCellIndicator", { clear = true }),
			callback = cell_indicator,
		})
	end,
}
