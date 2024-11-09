return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        show_hidden_count = true,
        hide_dotfiles = false,
        hide_gitignored = false,
        hide_hidden = false,
        never_show = {},
      },
    },

    window = {
      mappings = { ["/"] = "noop" },
      position = "right",
      width = 30,
    }
  }
}
