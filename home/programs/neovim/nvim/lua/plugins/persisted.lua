return {
  "olimorris/persisted.nvim",
  lazy = false,
  config = function ()
    require("persisted").setup {
      use_git_branch = true,
    }
    vim.opt.sessionoptions:append 'globals'
  end
}
