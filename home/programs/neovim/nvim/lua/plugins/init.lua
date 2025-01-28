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
        transparent_background_level = 0,
        italics = true,
        disable_italic_comments = true,
        sign_column_background = "none",
        ui_contrast = "low",
        dim_inactive_windows = false,
        diagnostic_text_highlight = true,
        diagnostic_virtual_text = "coloured",
        diagnostic_line_highlight = true,
        spell_foreground = false,
        inlay_hints_background = "dimmed",
        show_eob = false,
        float_style = "bright"
      })
    end,
  },
}
