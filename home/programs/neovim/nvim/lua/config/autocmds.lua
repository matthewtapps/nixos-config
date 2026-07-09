local function augroup(name)
  return vim.api.nvim_create_augroup("lazyvim_" .. name, { clear = true })
end

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
	group = augroup("highlight_yank"),
	callback = function()
		(vim.hl or vim.highlight).on_yank()
	end,
})

-- close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
	group = augroup("close_with_q"),
	pattern = {
		"PlenaryTestPopup",
		"checkhealth",
		"dbout",
		"gitsigns-blame",
		"grug-far",
		"help",
		"lspinfo",
		"neotest-output",
		"neotest-output-panel",
		"neotest-summary",
		"notify",
		"qf",
		"spectre_panel",
		"startuptime",
		"tsplayground",
	},
	callback = function(event)
		vim.bo[event.buf].buflisted = false
		vim.schedule(function()
			vim.keymap.set("n", "q", function()
				vim.cmd("close")
				pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
			end, {
				buffer = event.buf,
				silent = true,
				desc = "Quit buffer",
			})
		end)
	end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function()
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(0) then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})

-- Soft-wrap prose files. Global `wrap = false` (options.lua) keeps code files
-- unwrapped, but markdown player-sheets hold long unbroken paragraphs (and raw
-- HTML blocks like the pandoc banner) that otherwise run off-screen. linebreak
-- wraps at word boundaries; breakindent keeps wrapped lines visually indented.
vim.api.nvim_create_autocmd("FileType", {
	group = augroup("prose_wrap"),
	pattern = { "markdown", "markdown.mdx", "text" },
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.linebreak = true
		vim.opt_local.breakindent = true
		-- render-markdown.nvim's recommended wrap settings: keep wrapped rows
		-- indented under their start and reserve a 2-space hang so rendered
		-- icons/bars line up on continuation lines.
		vim.opt_local.breakindentopt = ""
		vim.opt_local.showbreak = "  "
	end,
})

-- Enable treesitter highlighting + indent (nvim-treesitter main branch is
-- provided by Nix; it does not auto-enable highlighting).
vim.api.nvim_create_autocmd("FileType", {
	group = augroup("treesitter_start"),
	callback = function(args)
		if not pcall(vim.treesitter.start, args.buf) then
			return
		end
		vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
	end,
})
