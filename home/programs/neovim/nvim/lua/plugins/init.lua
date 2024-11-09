return {
  {
    "neanias/everforest-nvim",
    priority = 1000,
    lazy = false,
    version = false,
    config = function()
      vim.cmd([[colorscheme everforest]])
      require("everforest").setup({
        on_highlights = function(hl, palette)
          hl.NeoTreeNormal = { fg = palette.fg, bg = palette.bg1 }
          hl.NeoTreeNormalNC = { fg = palette.fg, bg = palette.bg1 }
          hl.LazyDir = { fg = palette.fg, bg = palette.bg1 }
          hl.LazyNormal = { fg = palette.fg, bg = palette.bg1 }
        end
      })
    end,
  },
}
