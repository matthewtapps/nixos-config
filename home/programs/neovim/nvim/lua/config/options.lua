vim.opt.nu = true

vim.opt.relativenumber = true

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true

vim.opt.hlsearch = true
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.opt.colorcolumn = "80"

vim.g.mapleader = " "

vim.opt.autowrite = true
vim.opt.autowriteall = true
vim.opt.autoindent = true
vim.opt.list = true
vim.o.timeout = true
vim.o.timeoutlen = 1000

vim.g.snacks_animate = false

vim.filetype.add({
  pattern = {
    [".*%.html%.hbs"] = "handlebars.html"
  }
})
