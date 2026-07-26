-- Scrolling continuity across rendered tables.
--
-- A rendered table is one virt_lines block, and Neovim's scroll code treats
-- such a block as atomic: asked to scroll into one it snaps the view to before
-- the whole thing. Left alone that puts the table's edge on the window's edge
-- and throws the cursor across the screen. These assert the cursor keeps moving
-- one row at a time through a table, the way it does through prose.
local h = require("tests.helpers")
local ui = require("tests.ui")

-- One row of slack: the (topline, topfill) representation cannot express "the
-- anchor's text at the top with none of its block showing", so a single step
-- either side of a block can land a row out. Anything larger is a real jump.
local SLACK = 2

h.test("descending into a table keeps the cursor's screen row continuous", function()
  local chan = ui.start({ rows = 40, scrolloff = 8 })
  local ok, err = pcall(function()
    ui.open(chan, ui.doc(30, 6, 40))
    ui.exec(chan, [[vim.api.nvim_win_set_cursor(0, {22, 0}) vim.fn.winrestview({topline = 1, topfill = 0})]])
    ui.settle(chan)

    local rows = ui.walk(chan, "j", 14)
    h.assert_true("cursor never jumps entering the table", ui.biggest_step(rows) <= SLACK)
  end)
  ui.stop(chan)
  if not ok then
    error(err, 0)
  end
end)

h.test("ascending into a table keeps the cursor's screen row continuous", function()
  local chan = ui.start({ rows = 40, scrolloff = 8 })
  local ok, err = pcall(function()
    ui.open(chan, ui.doc(30, 6, 40))
    ui.exec(chan, [[vim.api.nvim_win_set_cursor(0, {56, 0}) vim.fn.winrestview({topline = 41, topfill = 0})]])
    ui.settle(chan)

    -- Walks down through the prose below the table, across its bottom edge and
    -- on into the rendered rows. This is the direction that used to jump by the
    -- block's whole height.
    local rows = ui.walk(chan, "k", 20)
    h.assert_true("cursor never jumps entering the table from below", ui.biggest_step(rows) <= SLACK)
  end)
  ui.stop(chan)
  if not ok then
    error(err, 0)
  end
end)

h.test("a table taller than the window is entered without a jump", function()
  local chan = ui.start({ rows = 40, scrolloff = 8 })
  local ok, err = pcall(function()
    -- 40 body rows render well past the window height, so the block cannot be
    -- shown whole and has to be scrolled into progressively.
    ui.open(chan, ui.doc(30, 40, 40))
    ui.exec(chan, [[vim.api.nvim_win_set_cursor(0, {22, 0}) vim.fn.winrestview({topline = 1, topfill = 0})]])
    ui.settle(chan)

    local rows = ui.walk(chan, "j", 14)
    h.assert_true("cursor never jumps entering a tall table", ui.biggest_step(rows) <= SLACK)
  end)
  ui.stop(chan)
  if not ok then
    error(err, 0)
  end
end)

h.test("half-page scrolling keeps the cursor on its screen row", function()
  local chan = ui.start({ rows = 40, scrolloff = 8 })
  local ok, err = pcall(function()
    ui.open(chan, ui.doc(30, 6, 40))
    ui.exec(chan, [[vim.api.nvim_win_set_cursor(0, {12, 0}) vim.fn.winrestview({topline = 1, topfill = 0})]])
    ui.settle(chan)

    -- <C-d> moves view and cursor together, so the cursor's screen row is the
    -- one thing that must NOT change — including over a table and back out.
    local start = ui.screen_row(chan)
    for i = 1, 3 do
      ui.feed(chan, "<C-d>")
      h.assert_eq("screen row held across <C-d> #" .. i, ui.screen_row(chan), start)
    end
  end)
  ui.stop(chan)
  if not ok then
    error(err, 0)
  end
end)

h.test("cursor tracking ignores a table's source lines when their height lies", function()
  -- The guard cannot key off the line's measured height. With 'wrap' on, a
  -- conceal_lines row reports height 1 rather than 0 (measured in a real
  -- config), so the crossing keypress recorded the concealed line as the
  -- cursor's last position — and focus mode, measuring the block's placement
  -- from it, then added the block's entire height. The table's top was shoved
  -- down to the scrolloff margin.
  --
  -- line_height is stubbed to lie exactly as it does there, so this pins the
  -- guard rather than the environment that exposed it.
  local chan = ui.start({ rows = 40, scrolloff = 8, wrap = true })
  local ok, err = pcall(function()
    ui.open(chan, ui.doc(30, 6, 40, true))
    local res = ui.exec(chan, [[
      local vp = require("markdown-table-wrap.viewport")
      local win, buf = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()

      vp.line_height = function() return 1, 0 end

      -- Baseline on the prose line just past the table (line 39).
      vim.api.nvim_win_set_cursor(win, { 39, 0 })
      vp.follow(win, buf)
      local before = vp.last(win)

      -- Cross into the table's last source line, as k does.
      vim.api.nvim_win_set_cursor(win, { 38, 0 })
      vp.follow(win, buf)
      local after = vp.last(win)

      return {
        in_table = vp.in_table(buf, 38),
        before = before and before.lnum or -1,
        after = after and after.lnum or -1,
      }
    ]])
    h.assert_true("line 38 is recognised as inside the table", res.in_table)
    h.assert_eq("baseline recorded on the prose line", res.before, 39)
    h.assert_eq("table line did not overwrite it", res.after, 39)
  end)
  ui.stop(chan)
  if not ok then
    error(err, 0)
  end
end)

h.test("entering a table from below does not jump by the block's height", function()
  -- Soft-wrapped prose with gj/gk motion: the arrangement under which the
  -- keypress that crosses into a table lands on one of its zero-height source
  -- lines while that line still measures non-zero. Recording THAT as the
  -- previous cursor position made focus mode add the block's whole height,
  -- shoving the table's top down to the scrolloff margin.
  local chan = ui.start({
    rows = 40,
    scrolloff = 8,
    wrap = true,
    screen_line_motion = true,
    debounce_ms = 80,
  })
  local ok, err = pcall(function()
    ui.open(chan, ui.doc(30, 6, 40, true))
    ui.exec(chan, [[vim.api.nvim_win_set_cursor(0, {45, 0}) vim.cmd("normal! zz")]])
    ui.settle(chan)

    local rows = ui.walk(chan, "k", 12)
    h.assert_true(
      "no jump crossing into the table, rows: " .. table.concat(rows, ","),
      ui.biggest_step(rows) <= SLACK
    )
  end)
  ui.stop(chan)
  if not ok then
    error(err, 0)
  end
end)

h.test("insert mode keeps the cursor on its screen row", function()
  -- Dropping the rendering for insert mode collapses the document by the
  -- difference between a table's rendered and source height; restoring it
  -- expands it again. The edited line has to stay where it was.
  local chan = ui.start({ rows = 40, scrolloff = 8, wrap = true })
  local ok, err = pcall(function()
    ui.open(chan, ui.doc(30, 6, 40, true))
    for _, lnum in ipairs({ 45, 50 }) do
      ui.exec(chan, ([[vim.api.nvim_win_set_cursor(0, {%d, 0}) vim.cmd("normal! zz")]]):format(lnum))
      ui.settle(chan)

      local before = ui.screen_row(chan)
      ui.feed(chan, "i")
      h.assert_true("row held entering insert at line " .. lnum, math.abs(ui.screen_row(chan) - before) <= 1)
      ui.feed(chan, "<Esc>")
      h.assert_true("row held leaving insert at line " .. lnum, math.abs(ui.screen_row(chan) - before) <= 1)
    end
  end)
  ui.stop(chan)
  if not ok then
    error(err, 0)
  end
end)

h.test("scrolloff holds deep inside a table taller than the window", function()
  -- 'topfill' is capped at the window height, so for a block taller than the
  -- window the source can only express "block starts at row 2 or below" and
  -- "the block's last win_h rows" — nothing between. Navigating into the hole
  -- used to leave the cursor pinned against the window edge with no margin at
  -- all, the table behaving as if it were the whole buffer.
  local chan = ui.start({ rows = 40, cols = 90, scrolloff = 8, wrap = true })
  local ok, err = pcall(function()
    ui.open(chan, ui.doc(30, 30, 40, true))
    ui.exec(chan, [[vim.api.nvim_win_set_cursor(0, {25, 0}) vim.fn.winrestview({topline = 1, topfill = 0})]])
    ui.settle(chan)

    local win_h = ui.exec(chan, [[return vim.api.nvim_win_get_height(0)]])
    local rendered = ui.exec(chan, [[
      local p = require("markdown-table-wrap.parser")
      return require("markdown-table-wrap.view").rendered_height(p.parse_at_cursor(0, 31), 0)
    ]])
    h.assert_true("the table really is taller than the window", rendered > win_h)

    local worst_low, worst_high = math.huge, -math.huge
    for _ = 1, 45 do
      ui.feed(chan, "j")
      local row = ui.screen_row(chan)
      worst_low = math.min(worst_low, row)
      worst_high = math.max(worst_high, row)
    end
    h.assert_true("cursor stayed below the top margin, lowest row " .. worst_low, worst_low >= 8)
    h.assert_true(
      "cursor stayed above the bottom margin, highest row " .. worst_high,
      worst_high <= win_h - 8 + 1
    )
  end)
  ui.stop(chan)
  if not ok then
    error(err, 0)
  end
end)

h.test("the scrolloff margin still holds at a table's edge", function()
  local chan = ui.start({ rows = 40, scrolloff = 8 })
  local ok, err = pcall(function()
    ui.open(chan, ui.doc(30, 6, 40))
    ui.exec(chan, [[vim.api.nvim_win_set_cursor(0, {56, 0}) vim.fn.winrestview({topline = 41, topfill = 0})]])
    ui.settle(chan)

    local rows = ui.walk(chan, "k", 20)
    local lowest = math.min(unpack(rows))
    -- Scrolling up, the cursor should stop at the margin and push the view
    -- instead. It used to run to the very top row once a table was involved.
    h.assert_true("cursor stays below the scrolloff margin, got row " .. lowest, lowest >= 8)
  end)
  ui.stop(chan)
  if not ok then
    error(err, 0)
  end
end)
