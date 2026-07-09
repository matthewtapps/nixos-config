vim.keymap.set("i", "jj", "<Esc>")
vim.keymap.set("i", "<C-H>", "<C-W>")   -- ctrl+backspace: legacy terminals (^H)
vim.keymap.set("i", "<C-BS>", "<C-W>") -- ctrl+backspace: kitty keyboard protocol (Ghostty+nvim)

vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Move by visual (screen) lines through wrapped lines, but keep counted jumps
-- logical so relativenumber targets still work: bare j/k glide across wrapped
-- rows; `5j` (read off the gutter) moves 5 real lines. Left unmapped in
-- operator-pending mode, so dj/yk still act on whole logical lines.
for _, k in ipairs({ "j", "<Down>" }) do
	vim.keymap.set({ "n", "x" }, k, function()
		return vim.v.count == 0 and "gj" or "j"
	end, { expr = true, silent = true, desc = "Down (visual line)" })
end
for _, k in ipairs({ "k", "<Up>" }) do
	vim.keymap.set({ "n", "x" }, k, function()
		return vim.v.count == 0 and "gk" or "k"
	end, { expr = true, silent = true, desc = "Up (visual line)" })
end

-- Terminal navigation (for when inside nvim terminals)
vim.keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h")
vim.keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>j")
vim.keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>k")
vim.keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>l")

-- Quick save
vim.keymap.set("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })

-- Better window navigation (this will work within nvim splits)
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")

-- Lazy
vim.keymap.set("n", "<leader>l", "<cmd>Lazy<cr>", { desc = "Lazy" })

-- diagnostic
local diagnostic_goto = function(next, severity)
	local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
	severity = severity and vim.diagnostic.severity[severity] or nil
	return function()
		go({ severity = severity })
	end
end
vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
vim.keymap.set("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
vim.keymap.set("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
vim.keymap.set("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
vim.keymap.set("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
vim.keymap.set("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
vim.keymap.set("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })

-- lazygit
local function git_root()
	return vim.fs.root(0, ".git") or vim.uv.cwd()
end

if vim.fn.executable("lazygit") == 1 then
	-- Lazygit's nvim-remote preset emits nushell syntax when $NU_VERSION is set
	-- or $SHELL ends in nu/nushell, but in practice bash ends up executing it
	-- from inside nvim. Force the bash variant by clearing both signals only
	-- for the lazygit subprocess.
	local lazygit_env = {
		SHELL = "/run/current-system/sw/bin/bash",
		NU_VERSION = "",
	}
	vim.keymap.set("n", "<leader>gg", function()
		Snacks.lazygit({ cwd = git_root(), env = lazygit_env })
	end, { desc = "Lazygit (Root Dir)" })
	vim.keymap.set("n", "<leader>gG", function()
		Snacks.lazygit({ env = lazygit_env })
	end, { desc = "Lazygit (cwd)" })
	vim.keymap.set("n", "<leader>gf", function()
		Snacks.picker.git_log_file()
	end, { desc = "Git Current File History" })
	vim.keymap.set("n", "<leader>gl", function()
		Snacks.picker.git_log({ cwd = git_root() })
	end, { desc = "Git Log" })
	vim.keymap.set("n", "<leader>gL", function()
		Snacks.picker.git_log()
	end, { desc = "Git Log (cwd)" })
end

vim.keymap.set("n", "<leader>gb", function()
	Snacks.picker.git_log_line()
end, { desc = "Git Blame Line" })
vim.keymap.set({ "n", "x" }, "<leader>gB", function()
	Snacks.gitbrowse()
end, { desc = "Git Browse (open)" })
vim.keymap.set({ "n", "x" }, "<leader>gY", function()
	Snacks.gitbrowse({
		open = function(url)
			vim.fn.setreg("+", url)
		end,
		notify = false,
	})
end, { desc = "Git Browse (copy)" })

-- quit
vim.keymap.set("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit All" })

-- highlights under cursor
vim.keymap.set("n", "<leader>ui", vim.show_pos, { desc = "Inspect Pos" })
vim.keymap.set("n", "<leader>uI", function()
	vim.treesitter.inspect_tree()
	vim.api.nvim_input("I")
end, { desc = "Inspect Tree" })

-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
vim.keymap.set("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
vim.keymap.set("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
vim.keymap.set("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
vim.keymap.set("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
vim.keymap.set("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
vim.keymap.set("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })

-- better indenting
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- commenting
vim.keymap.set("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Below" })
vim.keymap.set("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Above" })

-- Prevent conflict with manual code format
vim.keymap.set("n", "d<Space>", "x", { desc = "Delete character" })

vim.keymap.set("n", "<Esc>", function()
	vim.cmd("noh")
end, { desc = "Exit search highlight" })
