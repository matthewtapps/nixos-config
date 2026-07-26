-- Viewport arithmetic in RENDERED rows.
--
-- A rendered table is one `virt_lines` block hanging off an anchor line, and
-- the table's own source lines have zero height (`conceal_lines`). Neovim's
-- scrolling works in buffer lines plus 'topfill', and its own scroll code will
-- not stop part-way into such a block: asked to scroll up past one it snaps the
-- topline back to before the whole thing, so the table's top edge lands on the
-- window's top edge and the cursor jumps by the block's full height.
--
-- Everything here works in the coordinate system the user actually sees — screen
-- rows — and drives (topline, topfill) explicitly to hit an exact row.
local M = {}

-- Screen rows `lnum` occupies, and how many of those are virtual.
--   all  — total rows, virtual lines included
--   fill — the virtual ones (a rendered table block)
-- A concealed table source line is all = 0.
function M.line_height(win, lnum)
  local ok, height = pcall(vim.api.nvim_win_text_height, win, { start_row = lnum - 1, end_row = lnum - 1 })
  if not ok then
    return 1, 0
  end
  return height.all, height.fill
end

-- Rows this line hangs ABOVE its own text (`virt_lines_above`). Only such a
-- block can be scrolled into part-way, via 'topfill'.
function M.above_fill(bufnr, lnum)
  local namespace = require("markdown-table-wrap.inline").namespace()
  local marks = vim.api.nvim_buf_get_extmarks(bufnr, namespace, { lnum - 1, 0 }, { lnum - 1, -1 }, { details = true })
  local rows = 0
  for _, mark in ipairs(marks) do
    local details = mark[4]
    if details and details.virt_lines and details.virt_lines_above then
      rows = rows + #details.virt_lines
    end
  end
  return rows
end

--- Whether `lnum` falls inside a table that is currently rendered as a block.
function M.in_table(bufnr, lnum)
  for _, info in ipairs(require("markdown-table-wrap.inline").tables(bufnr)) do
    if lnum >= info.start_lnum and lnum <= info.end_lnum then
      return true
    end
  end
  return false
end

-- Screen rows between the first TEXT row of `from` and that of `to` (from < to).
-- A line's own leading fill sits above its text, so it belongs to the line
-- before it: drop `from`'s and add `to`'s.
function M.distance(win, bufnr, from, to)
  if from == to then
    return 0
  end
  if from > to then
    return -M.distance(win, bufnr, to, from)
  end
  local ok, height = pcall(vim.api.nvim_win_text_height, win, { start_row = from - 1, end_row = to - 2 })
  if not ok then
    return to - from
  end
  return height.all - M.above_fill(bufnr, from) + M.above_fill(bufnr, to)
end

-- Every (topline, topfill) pair that puts `lnum`'s text at a known screen row,
-- cheapest first, walking up until the window is filled.
--
-- 'topfill' is the count of virtual rows drawn above the topline's own text, so
-- a line with `f` rows of leading fill offers views 1..f. It does NOT offer 0:
-- Neovim rejects a topline whose fill is entirely hidden and snaps back to
-- before the block (measured: topline 39 topfill 0 -> topline 30). Anchor lines
-- therefore start at 1, and the row that would sit between two blocks is simply
-- not reachable.
local function candidates(win, bufnr, lnum, limit)
  local list = {}
  local function add(topline, topfill, rows)
    list[#list + 1] = { topline = topline, topfill = topfill, rows = rows }
  end

  local own = M.above_fill(bufnr, lnum)
  for t = 1, own do
    add(lnum, t, t)
  end
  if own == 0 then
    add(lnum, 0, 0)
  end

  local acc = own
  local line = lnum
  while acc < limit and line > 1 do
    line = line - 1
    local all = M.line_height(win, line)
    if all > 0 then
      local fill = M.above_fill(bufnr, line)
      local text_rows = all - fill
      for t = 1, fill do
        add(line, t, acc + text_rows + t)
      end
      if fill == 0 then
        add(line, 0, acc + all)
      end
      acc = acc + all
    end
  end

  -- Top of the buffer: nothing above line 1, so this is the highest row `lnum`
  -- can reach and it must stay reachable even when it undershoots the target.
  if line <= 1 then
    add(1, M.above_fill(bufnr, 1), acc)
  end
  return list
end

--- Scroll `win` so `lnum`'s first text row sits at screen row `want_row`.
--- Returns the row actually achieved — the representation is not dense, so a
--- request can land a row or two off.
---
--- `bounds` = { min_rows, max_rows } restricts which rows are acceptable. The
--- caller passes the scrolloff band: landing even one row outside it makes
--- Neovim re-enforce the margin itself, and its correction re-snaps the whole
--- block — undoing the placement and reinstating the jump being fixed here.
function M.place(win, bufnr, lnum, want_row, bounds)
  -- Not capped at the window height: a block taller than the window puts its
  -- anchor's text off the bottom, and that is a legitimate view.
  local need = math.max(0, want_row - 1)

  local best, fallback
  for _, c in ipairs(candidates(win, bufnr, lnum, need)) do
    local cost = math.abs(c.rows - need)
    if not fallback or cost < fallback.cost then
      fallback = { cost = cost, view = c }
    end
    local inside = not bounds or (c.rows >= bounds[1] and c.rows <= bounds[2])
    if inside and (not best or cost < best.cost) then
      best = { cost = cost, view = c }
    end
  end
  best = best or fallback
  if not best then
    return nil
  end

  vim.api.nvim_win_call(win, function()
    vim.fn.winrestview({ topline = best.view.topline, topfill = best.view.topfill, skipcol = 0 })
  end)
  return best.view.rows + 1
end

--- Scroll `win` so the first rendered row of `table_info`'s block sits at screen
--- row `want_row`. `want_row` may be <= 0 for a block scrolled part-way off the
--- top. Returns the row achieved, or nil when the table is not rendered as a
--- block.
function M.place_block(win, bufnr, table_info, rendered_rows, want_row, config)
  local inline = require("markdown-table-wrap.inline")
  local anchor, above = inline.block_anchor(bufnr, table_info, config)
  if not anchor then
    return nil
  end
  -- Above-anchored: the block's rows are the anchor's leading fill, so the
  -- anchor's text sits `rendered_rows` below the block's first row. Otherwise
  -- the block is drawn under the anchor's text, one row after it.
  local anchor_row = above and (want_row + rendered_rows) or (want_row - 1)
  local got = M.place(win, bufnr, anchor, anchor_row)
  if not got then
    return nil
  end
  return above and (got - rendered_rows) or (got + 1)
end

--- The scrolloff margin actually in force for `win`, capped the way Neovim caps
--- it on a short window.
function M.margin(win)
  local so = vim.api.nvim_get_option_value("scrolloff", { win = win, scope = "local" })
  if so < 0 then
    so = vim.go.scrolloff
  end
  local win_h = vim.api.nvim_win_get_height(win)
  return math.min(so, math.floor((win_h - 1) / 2)), win_h
end

-- Where the cursor last sat, per window, so the next motion can be measured
-- against it. Kept in screen rows, which is the thing being made continuous.
local last = {}
local adjusting = false
-- Motions that placed themselves (see M.jump); the CursorMoved they raise must
-- not be re-derived from the previous row.
local claimed = {}

function M.last(win)
  return last[win]
end

function M.forget(win)
  last[win] = nil
  claimed[win] = nil
end

-- Refresh the remembered row without correcting anything — for view changes the
-- user asked for directly (zz, <C-e>, a resize), which must not be undone.
function M.note(win)
  if adjusting then
    return
  end
  local prev = last[win]
  if not prev or vim.api.nvim_win_get_cursor(win)[1] ~= prev.lnum then
    return
  end
  prev.row = vim.api.nvim_win_call(win, vim.fn.winline)
  prev.view = vim.api.nvim_win_call(win, vim.fn.winsaveview)
end

--- Keep the cursor's screen row moving by exactly the RENDERED distance
--- travelled, clamped to the scrolloff margins — what Neovim does everywhere
--- except across a table block, where it scrolls by the block's whole height.
---
--- No-op on the first move in a window, on a cursor sitting in a table's
--- zero-height source lines (focus mode owns those), and while a correction is
--- already in flight.
function M.follow(win, bufnr)
  if adjusting then
    return
  end
  if claimed[win] then
    claimed[win] = nil
    return
  end
  local lnum = vim.api.nvim_win_get_cursor(win)[1]
  local prev = last[win]

  -- A line inside a rendered table has no screen row of its own, so there is
  -- nothing to measure and nothing worth remembering: `last` must keep pointing
  -- at the last line that really had a row, because focus mode measures the
  -- block's placement from it. Recording the concealed line instead makes the
  -- entry land a whole block-height further down.
  --
  -- Asked of the table list, not of the line's height: a re-render can leave a
  -- table's lines briefly measuring non-zero, and this has to hold on exactly
  -- the keypress that crosses into one.
  if M.in_table(bufnr, lnum) or M.line_height(win, lnum) == 0 then
    -- Auto-focus opens on the next tick, but Neovim redraws before that, and it
    -- will scroll to "reveal" this zero-height line — drawing the document
    -- scrolled clean past the rendered block for one frame. Focus mode then
    -- puts it back, which is the visible stutter on entering a table. Undo the
    -- reveal now, while it is still the same frame.
    local kept = prev and prev.view
    if kept then
      vim.api.nvim_win_call(win, function()
        local now = vim.fn.winsaveview()
        if now.topline ~= kept.topline or (now.topfill or 0) ~= (kept.topfill or 0) then
          vim.fn.winrestview({ topline = kept.topline, topfill = kept.topfill, skipcol = kept.skipcol })
        end
      end)
    end
    return
  end

  if not prev or prev.buf ~= bufnr or prev.lnum == lnum then
    last[win] = {
      buf = bufnr,
      lnum = lnum,
      row = vim.api.nvim_win_call(win, vim.fn.winline),
      view = vim.api.nvim_win_call(win, vim.fn.winsaveview),
    }
    return
  end

  local margin, win_h = M.margin(win)
  local delta = M.distance(win, bufnr, prev.lnum, lnum)
  local want
  if math.abs(delta) >= win_h then
    -- Off-screen jump (G, a search hit): Neovim centres, and so do we.
    want = math.floor(win_h / 2)
  else
    want = math.max(margin + 1, math.min(prev.row + delta, win_h - margin))
  end

  adjusting = true
  local ok = pcall(M.place, win, bufnr, lnum, want, { margin, win_h - margin - 1 })
  adjusting = false

  last[win] = {
    buf = bufnr,
    lnum = lnum,
    row = ok and vim.api.nvim_win_call(win, vim.fn.winline) or want,
    view = vim.api.nvim_win_call(win, vim.fn.winsaveview),
  }
end

--- Record a cursor row explicitly — used when focus mode hands the cursor back
--- to the document, so the next motion continues from where it really is.
function M.set_last(win, bufnr, lnum, row)
  last[win] = {
    buf = bufnr,
    lnum = lnum,
    row = row,
    view = vim.api.nvim_win_call(win, vim.fn.winsaveview),
  }
end

--- Move the cursor to `lnum` and put it on screen row `want_row`, claiming the
--- motion so the CursorMoved it triggers does not re-derive a different row.
--- For motions that set their own destination — <C-d>/<C-u>, which move view
--- and cursor together and so must leave the cursor where it started.
function M.jump(win, bufnr, lnum, want_row)
  local margin, win_h = M.margin(win)
  want_row = math.max(margin + 1, math.min(want_row, win_h - margin))
  pcall(vim.api.nvim_win_set_cursor, win, { lnum, 0 })

  adjusting = true
  pcall(M.place, win, bufnr, lnum, want_row, { margin, win_h - margin - 1 })
  adjusting = false

  last[win] = {
    buf = bufnr,
    lnum = lnum,
    row = vim.api.nvim_win_call(win, vim.fn.winline),
    view = vim.api.nvim_win_call(win, vim.fn.winsaveview),
  }
  claimed[win] = true
end

return M
