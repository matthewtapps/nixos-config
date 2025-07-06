vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.g.snacks_animate = false

vim.g.trouble_lualine = true

vim.opt.autowrite = true
vim.opt.autowriteall = true
vim.opt.autoindent = true
vim.opt.completeopt = "menu,menuone,noselect"

vim.opt.foldlevel = 99
vim.opt.conceallevel = 2
vim.opt.cursorline = true

vim.opt.expandtab = true
vim.opt.list = false
vim.opt.tabstop = 2
vim.opt.confirm = true
vim.opt.shiftround = true
vim.opt.shiftwidth = 2
vim.opt.showmode = false
vim.opt.sidescrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.smartindent = true
vim.opt.smartcase = true
vim.opt.spelllang = { "en" }
vim.opt.undolevels = 10000
vim.opt.virtualedit = "block"
vim.opt.wildmode = "longest:full,full"

vim.opt.mouse = "a"
vim.opt.pumblend = 10
vim.opt.pumheight = 10

vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.smartindent = true
vim.opt.wrap = false

vim.opt.clipboard = "unnamedplus"

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true

vim.opt.hlsearch = true
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.opt.colorcolumn = "80"
vim.opt.cmdheight = 0
vim.o.timeout = true
vim.o.timeoutlen = 1000

vim.filetype.add({
	pattern = {
		[".*%.html%.hbs"] = "handlebars.html",
	},
})
