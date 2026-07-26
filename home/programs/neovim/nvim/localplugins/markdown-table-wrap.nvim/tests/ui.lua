-- Drives a child Neovim with a REAL attached UI.
--
-- Scrolling behaviour cannot be asserted in a plain headless instance: with no
-- UI there is no screen grid, so screenpos() returns row 0 and the plugin's own
-- geometry code has nothing to measure. Spawning a child over RPC and calling
-- nvim_ui_attach on it gives a genuine 1-based screen grid to assert against.
local M = {}

local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")

function M.start(opts)
  opts = opts or {}
  local chan = vim.fn.jobstart({ "nvim", "--embed", "--headless", "-u", "NONE", "-n" }, { rpc = true })
  assert(chan > 0, "failed to spawn child nvim")
  -- Empty ui options: the child otherwise negotiates extensions this client
  -- does not implement.
  vim.rpcrequest(chan, "nvim_ui_attach", opts.cols or 100, opts.rows or 40, {})

  M.exec(
    chan,
    ([[
      vim.opt.runtimepath:prepend(%q)
      vim.opt.swapfile = false
      vim.o.scrolloff = %d
      vim.o.laststatus = 0
      vim.o.number = WRAP
      vim.o.wrap = WRAP
      require("markdown-table-wrap").setup({
        debounce_ms = DEBOUNCE,
        auto_preview = true,
        auto_focus = %s,
        inline_conceal_lines = true,
        render_all = true,
      })
    ]]):format(root, opts.scrolloff or 8, tostring(opts.auto_focus ~= false))
      :gsub("WRAP", tostring(opts.wrap == true))
      -- Default (80ms), not 0, whenever a test needs the real re-render cycle:
      -- mid-cycle a table's conceal marks are briefly gone and its lines
      -- measure non-zero, which is when the cursor-tracking guard matters.
      :gsub("DEBOUNCE", tostring(opts.debounce_ms or 0))
  )

  if opts.screen_line_motion then
    -- Bare j/k mapped to gj/gk, as a soft-wrapped prose config normally does.
    M.exec(
      chan,
      [[
        for _, k in ipairs({ "j" }) do
          vim.keymap.set({ "n", "x" }, k, function() return vim.v.count == 0 and "gj" or "j" end, { expr = true })
        end
        for _, k in ipairs({ "k" }) do
          vim.keymap.set({ "n", "x" }, k, function() return vim.v.count == 0 and "gk" or "k" end, { expr = true })
        end
      ]]
    )
  end
  return chan
end

function M.stop(chan)
  pcall(vim.fn.jobstop, chan)
end

function M.exec(chan, code)
  return vim.rpcrequest(chan, "nvim_exec_lua", code, {})
end

-- Let scheduled callbacks (auto-focus defers through vim.schedule) and the
-- redraws they depend on actually run.
function M.settle(chan)
  for _ = 1, 3 do
    vim.rpcrequest(chan, "nvim_command", "redraw")
    vim.rpcrequest(chan, "nvim_eval", "1")
  end
end

function M.open(chan, lines)
  vim.rpcrequest(chan, "nvim_buf_set_lines", 0, 0, -1, false, lines)
  M.exec(chan, [[
    vim.bo.filetype = "markdown"
    require("markdown-table-wrap").refresh_auto({ force = true })
  ]])
  M.settle(chan)
end

function M.feed(chan, keys)
  vim.rpcrequest(chan, "nvim_input", keys)
  M.settle(chan)
end

--- The cursor's absolute screen row, whether it sits in the document or in the
--- focus float — the number the user perceives as "where the cursor is".
function M.screen_row(chan)
  return M.exec(chan, [[return vim.fn.win_screenpos(0)[1] + vim.fn.winline() - 1]])
end

--- A document of `above` prose lines, a table of `rows` body rows, then `below`
--- more prose lines. The table starts at line `above + 1`.
function M.doc(above, rows, below, wide)
  local lines = {}
  local prose = wide and "prose line %02d with a good few more words in it" or "prose %02d"
  local tail = wide and "tail line %02d with a good few more words in it" or "tail %02d"
  for i = 1, above do
    lines[#lines + 1] = prose:format(i)
  end
  if wide then
    lines[#lines + 1] = "| Column A | Column B | Column C |"
    lines[#lines + 1] = "| --- | --- | --- |"
    for i = 1, rows do
      lines[#lines + 1] = ("| row %d alpha | row %d beta with a fair amount of text | row %d gamma |"):format(i, i, i)
    end
  else
    lines[#lines + 1] = "| Col A | Col B |"
    lines[#lines + 1] = "| --- | --- |"
    for i = 1, rows do
      lines[#lines + 1] = ("| row %d a | row %d b |"):format(i, i)
    end
  end
  for i = 1, below do
    lines[#lines + 1] = tail:format(i)
  end
  return lines
end

--- Press `key` `count` times, returning the cursor's screen row after each.
function M.walk(chan, key, count)
  local rows = { M.screen_row(chan) }
  for _ = 1, count do
    M.feed(chan, key)
    rows[#rows + 1] = M.screen_row(chan)
  end
  return rows
end

--- Largest step between consecutive entries.
function M.biggest_step(rows)
  local worst = 0
  for i = 2, #rows do
    worst = math.max(worst, math.abs(rows[i] - rows[i - 1]))
  end
  return worst
end

return M
