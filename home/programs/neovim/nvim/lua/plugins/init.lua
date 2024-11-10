return {
  {
    "neanias/everforest-nvim",
    priority = 1000,
    lazy = false,
    version = false,
    config = function()
      vim.cmd([[colorscheme everforest]])
      require("everforest").setup({
        background = "soft",
      })
    end,
  },
}
