return {
  -- {
  --   "folke/edgy.nvim",
  --   opts = function()
  --     local opts = {
  --       animate = {
  --         enabled = true,
  --         fps = 144,
  --         cps = 144
  --       },
  --       wo = {
  --         winhighlight = "WinBar:EdgyNormal"
  --       },
  --       left = {},
  --       right = {
  --         { title = "Neotree Filesystem", ft = "neo-tree",        pinned = true },
  --         { title = "Neotest Summary",    ft = "neotest-summary", pinned = false, size = { height = 0.3 } },
  --       },
  --       bottom = {
  --         { ft = "qf",                   title = "Quickfix" },
  --         "Trouble",
  --         { ft = "neotest-output-panel", title = "Neotest Output", size = { height = 15 } },
  --         { title = "Spectre",           ft = "spectre_panel",     size = { height = 0.4 } },
  --         {
  --           ft = "help",
  --           size = { height = 20 },
  --           -- don't open help files in edgy that we're editing
  --           filter = function(buf)
  --             return vim.bo[buf].buftype == "help"
  --           end,
  --         },
  --         keys = {
  --           -- increase width
  --           ["<c-Right>"] = function(win)
  --             win:resize("width", 2)
  --           end,
  --           -- decrease width
  --           ["<c-Left>"] = function(win)
  --             win:resize("width", -2)
  --           end,
  --           -- increase height
  --           ["<c-Up>"] = function(win)
  --             win:resize("height", 2)
  --           end,
  --           -- decrease height
  --           ["<c-Down>"] = function(win)
  --             win:resize("height", -2)
  --           end,
  --         },
  --       },
  --     }
  --
  --     -- if LazyVim.has("neo-tree.nvim") then
  --     --   local pos = {
  --     --     filesystem = "right",
  --     --     buffers = "top",
  --     --     git_status = "right",
  --     --     document_symbols = "bottom",
  --     --     diagnostics = "bottom",
  --     --   }
  --     --   local sources = LazyVim.opts("neo-tree.nvim").sources or {}
  --     --   for i, v in ipairs(sources) do
  --     --     table.insert(opts.right, i, {
  --     --       title = "Neo-Tree " .. v:gsub("_", " "):gsub("^%l", string.upper),
  --     --       ft = "neo-tree",
  --     --       filter = function(buf)
  --     --         return vim.b[buf].neo_tree_source == v
  --     --       end,
  --     --       pinned = false,
  --     --       open = function()
  --     --         vim.cmd(("Neotree show position=%s %s dir=%s"):format(pos[v] or "bottom", v, LazyVim.root()))
  --     --       end,
  --     --     })
  --     --   end
  --     -- end
  --
  --     for _, pos in ipairs({ "top", "bottom", "left", "right" }) do
  --       opts[pos] = opts[pos] or {}
  --       table.insert(opts[pos], {
  --         ft = "snacks_terminal",
  --         size = { height = 0.4 },
  --         title = "%{b:snacks_terminal.id}: %{b:term_title}",
  --         filter = function(_buf, win)
  --           return vim.w[win].snacks_win
  --               and vim.w[win].snacks_win.position == pos
  --               and vim.w[win].snacks_win.relative == "editor"
  --               and not vim.w[win].trouble_preview
  --         end,
  --       })
  --     end
  --     return opts
  --   end
  -- },
}