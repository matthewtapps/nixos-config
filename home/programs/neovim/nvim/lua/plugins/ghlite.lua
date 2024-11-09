return {
  'daliusd/ghlite.nvim',
  config = function()
    require('ghlite').setup({
      debug = false,           -- if set to true debugging information is written to ~/.ghlite.log file
      view_split = 'vsplit',   -- set to empty string '' to open in active buffer
      diff_split = 'vsplit',   -- set to empty string '' to open in active buffer
      comment_split = 'split', -- set to empty string '' to open in active buffer
      open_command = 'open',   -- open command to use, e.g. on Linux you might want to use xdg-open
      keymaps = {              -- override default keymaps with the ones you prefer
        diff = {
          open_file = 'gf',
          open_file_tab = 'gt',
          open_file_split = 'gs',
          open_file_vsplit = 'gv',
          approve = '<C-A>',
        },
        comment = {
          send_comment = '<C-CR>'
        },
        pr = {
          approve = '<C-A>',
        },
      },
    })
  end,
  keys = {
    { '<leader>gus', ':GHLitePRSelect<cr>',        silent = true },
    { '<leader>guo', ':GHLitePRCheckout<cr>',      silent = true },
    { '<leader>guv', ':GHLitePRView<cr>',          silent = true },
    { '<leader>guu', ':GHLitePRLoadComments<cr>',  silent = true },
    { '<leader>gup', ':GHLitePRDiff<cr>',          silent = true },
    { '<leader>gul', ':GHLitePRDiffview<cr>',      silent = true },
    { '<leader>gua', ':GHLitePRAddComment<cr>',    silent = true },
    { '<leader>guc', ':GHLitePRUpdateComment<cr>', silent = true },
    { '<leader>gud', ':GHLitePRDeleteComment<cr>', silent = true },
    { '<leader>gug', ':GHLitePROpenComment<cr>',   silent = true },
  }
}
