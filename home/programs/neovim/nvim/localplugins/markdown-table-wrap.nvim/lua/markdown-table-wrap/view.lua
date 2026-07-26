-- Focus mode: a real (read-only) buffer containing the rendered table, opened
-- in a borderless float positioned exactly over the table. The cursor moves
-- through the pretty table with normal Vim motions; i/a/<CR> edits the cell
-- under the cursor in place (live write-through to the source), <Esc>/q drops
-- back to the corresponding source cell.
local M = {}

local state = nil
-- After an explicit exit onto the table's own source lines (Esc/q), skip
-- auto-enter until the cursor leaves that range, else it would reopen at once.
local suppressed = {}
-- Last known cursor line per buffer and the pending entry direction: only a
-- true adjacent-line arrival (j from above / k from below) lands on the
-- borders; jumps (search, G) map to the exact cell and column.
local last_lnum = {}
local entry_hint = nil
-- Set by M.enter_at: the rendered row focus mode should open on, when the
-- caller already knows it (screen-row scrolling landing inside a table), and
-- the window row that rendered row should be drawn at.
local entry_row = nil
local entry_screen_row = nil

local function rendered_for(source_win, table_info, config)
  local render = require("markdown-table-wrap.render")
  -- render_table sizes columns from the current window; use the source window
  -- even when called from inside the float.
  return vim.api.nvim_win_call(source_win, function()
    return render.render_table(table_info, config)
  end)
end

local function cell_at(rendered, row, col)
  local line_obj = rendered.line_objects[row]
  if not line_obj or not line_obj.cells then
    return nil
  end
  for index, range in ipairs(line_obj.cells) do
    if col >= range.start_col and col < range.end_col then
      return index, range, line_obj
    end
  end
  return nil
end

local function find_cell_line(rendered, source_lnum, cell_index)
  for row, line_obj in ipairs(rendered.line_objects) do
    if line_obj.source_lnum == source_lnum and line_obj.cells and line_obj.cells[cell_index] then
      return row, line_obj.cells[cell_index], line_obj
    end
  end
end

local function cell_block_height(rendered, source_lnum)
  local count = 0
  for _, line_obj in ipairs(rendered.line_objects) do
    if line_obj.source_lnum == source_lnum then
      count = count + 1
    end
  end
  return math.max(1, count)
end

local function fill_buffer(buf, rendered, config)
  local render = require("markdown-table-wrap.render")
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, rendered.lines)
  render.apply_float_highlights(buf, rendered.line_objects or rendered.lines, config)
  vim.bo[buf].modifiable = false
end

-- Absolute screen row of the table's FIRST rendered row, or nil when the whole
-- block is off screen. Both renderers draw exactly #rendered.lines contiguous
-- rows, but they hang them differently, so the row cannot be read off the
-- source line numbers:
--   * conceal_lines renderer — source lines have zero height and the block is
--     a virt_lines chunk on an anchor line just outside the table.
--   * overlay renderer — rendered row N sits on source line start+N-1, with the
--     surplus in a virt_lines chunk on the last source line.
local function block_top_row(source_win, info, rendered)
  local bufnr = vim.api.nvim_win_get_buf(source_win)

  -- Whichever renderer drew it, the block starts immediately after the last
  -- text row of the line before the table, and ends immediately before the
  -- first text row of the line after it. Measuring from those two ordinary
  -- lines works for both, and for either anchoring of the virt_lines chunk.
  --
  -- The line AFTER is measured first because it is the only one that stays
  -- exact once the block is scrolled part-way off the top: the view is then
  -- (topline inside the table's zero-height lines, topfill > 0), and
  -- screenpos() on the line BEFORE reports a row inside the fill rather than
  -- the 0 that means "off screen" — which reads as the block starting near the
  -- bottom of the window instead of above its top.
  local after = info.end_lnum + 1
  if after <= vim.api.nvim_buf_line_count(bufnr) then
    local sp = vim.fn.screenpos(source_win, after, 1)
    if sp.row > 0 then
      return sp.row - #rendered.lines
    end
  end

  local before = info.start_lnum - 1
  if before >= 1 then
    local sp = vim.fn.screenpos(source_win, before, 1)
    if sp.row > 0 then
      -- `fill` is the virtual lines counted in `all`; the rest is real text.
      local h = vim.api.nvim_win_text_height(source_win, { start_row = before - 1, end_row = before - 1 })
      return sp.row + (h.all - h.fill)
    end
  elseif vim.fn.screenpos(source_win, info.start_lnum, 1).row > 0 then
    -- Table at line 1 with its block anchored below: nothing above to measure
    -- from, and the table's own lines are hidden, so the block starts at the
    -- top of the window.
    return vim.fn.win_screenpos(source_win)[1]
  end

  -- Neither edge on screen: the block is taller than the window. 'topfill' is
  -- how many of its rows are still drawn above the first buffer line shown.
  local view = vim.api.nvim_win_call(source_win, vim.fn.winsaveview)
  if (view.topfill or 0) > 0 then
    return vim.fn.win_screenpos(source_win)[1] - (#rendered.lines - view.topfill)
  end
  return nil
end

-- Compute the float frame covering exactly the VISIBLE slice of the table,
-- never moving the source view. Whatever part of the block sits above the
-- window top is reported back as the float's internal topline, so the float
-- mirrors the visible slice rather than the whole table.
local function compute_frame(source_win, info, rendered, textoff)
  local win_h = vim.api.nvim_win_get_height(source_win)
  local wtop = vim.fn.win_screenpos(source_win)[1]
  local width = math.min(rendered.width + (textoff or 0), math.max(20, vim.api.nvim_win_get_width(source_win)))

  local top = block_top_row(source_win, info, rendered)
  local frame_row, hidden = 0, 0
  if top then
    frame_row = top - wtop
    hidden = math.min(math.max(0, -frame_row), #rendered.lines - 1)
    frame_row = math.max(0, math.min(frame_row, win_h - 1))
  end

  return {
    relative = "win",
    win = source_win,
    row = frame_row,
    col = 0,
    width = width,
    height = math.max(1, math.min(#rendered.lines - hidden, win_h - frame_row)),
  }, hidden > 0 and (hidden + 1) or nil
end

function M.is_open()
  return state ~= nil and vim.api.nvim_win_is_valid(state.win)
end

function M.close(return_to_cell)
  if not state then
    return
  end
  local s = state
  state = nil

  local cur_row, cur_col
  if vim.api.nvim_win_is_valid(s.win) then
    cur_row, cur_col = unpack(vim.api.nvim_win_get_cursor(s.win))
    vim.api.nvim_win_close(s.win, true)
  end

  if not vim.api.nvim_win_is_valid(s.source_win) then
    return
  end
  vim.api.nvim_set_current_win(s.source_win)
  if s.saved_scrolloff ~= nil then
    pcall(vim.api.nvim_set_option_value, "scrolloff", s.saved_scrolloff, { win = s.source_win, scope = "local" })
  end
  if s.saved_smooth ~= nil then
    pcall(vim.api.nvim_set_option_value, "smoothscroll", s.saved_smooth, { win = s.source_win, scope = "local" })
  end

  if return_to_cell and cur_row then
    suppressed[s.source_buf] = { s.table_info.start_lnum, s.table_info.end_lnum }
    local nav = require("markdown-table-wrap.nav")
    local index, _, line_obj = cell_at(s.rendered, cur_row, cur_col)
    if index and line_obj.source_lnum then
      local line = vim.api.nvim_buf_get_lines(s.source_buf, line_obj.source_lnum - 1, line_obj.source_lnum, false)[1]
        or ""
      local span = nav.spans(line)[index]
      -- Landing on a zero-height (conceal_lines) source line makes Neovim
      -- scroll to where that line "is" — past the whole rendered block. Put the
      -- view back so the document does not jump out from under the table.
      local view = vim.api.nvim_win_call(s.source_win, vim.fn.winsaveview)
      pcall(vim.api.nvim_win_set_cursor, s.source_win, { line_obj.source_lnum, span and span.start_col or 0 })
      vim.api.nvim_win_call(s.source_win, function()
        local now = vim.fn.winsaveview()
        if now.topline ~= view.topline or (now.topfill or 0) ~= (view.topfill or 0) then
          vim.fn.winrestview({ topline = view.topline, topfill = view.topfill, skipcol = view.skipcol })
        end
      end)
    end
  end
end

-- The focus cursor's row within the SOURCE window — the float is borderless and
-- sits inside it, so the two share a row origin once the frame offset is added.
local function cursor_screen_row()
  local s = state
  if not s or not vim.api.nvim_win_is_valid(s.win) then
    return nil
  end
  local absolute = vim.fn.win_screenpos(s.win)[1] + vim.api.nvim_win_call(s.win, vim.fn.winline) - 1
  return absolute - vim.fn.win_screenpos(s.source_win)[1] + 1
end

-- Close the float and drop the cursor `1 + spill` source lines past the
-- table, so j/k (and their counts) sail straight through: a 10k five rows
-- into the table exits and keeps going. When the table touches the buffer
-- edge there is nowhere to go; stay inside instead.
--
-- `want_row` is the source-window row the cursor should end on, so leaving a
-- table is as continuous as entering one.
local function exit_past(direction, spill, want_row)
  local s = state
  if not s or not vim.api.nvim_win_is_valid(s.source_win) then
    return
  end

  spill = spill or 0
  local target
  if direction > 0 then
    local last = vim.api.nvim_buf_line_count(s.source_buf)
    if s.table_info.end_lnum >= last then
      return
    end
    target = math.min(last, s.table_info.end_lnum + 1 + spill)
  else
    if s.table_info.start_lnum <= 1 then
      return
    end
    target = math.max(1, s.table_info.start_lnum - 1 - spill)
  end

  local source_win = s.source_win
  local source_buf = s.source_buf
  -- Restore the user's scrolloff/smoothscroll BEFORE placing the cursor, so
  -- the exit scroll obeys their own settings exactly like native motion.
  if s.saved_scrolloff ~= nil then
    pcall(vim.api.nvim_set_option_value, "scrolloff", s.saved_scrolloff, { win = source_win, scope = "local" })
  end
  if s.saved_smooth ~= nil then
    pcall(vim.api.nvim_set_option_value, "smoothscroll", s.saved_smooth, { win = source_win, scope = "local" })
  end
  pcall(vim.api.nvim_win_set_cursor, source_win, { target, 0 })
  M.close(false)
  if vim.api.nvim_win_is_valid(source_win) then
    vim.api.nvim_set_current_win(source_win)
    if want_row then
      require("markdown-table-wrap.viewport").jump(source_win, source_buf, target, want_row)
    end
  end
end

local function refresh(keep_cell)
  local s = state
  if not s then
    return
  end

  local parser = require("markdown-table-wrap.parser")
  local info = parser.parse_at_cursor(s.source_buf, s.table_info.start_lnum)
  if not info then
    M.close(false)
    return
  end

  s.table_info = info
  s.rendered = rendered_for(s.source_win, info, s.config)
  fill_buffer(s.buf, s.rendered, s.config)

  if vim.api.nvim_win_is_valid(s.win) then
    do
      local frame, internal_topline = compute_frame(s.source_win, info, s.rendered, s.textoff)
      vim.api.nvim_win_set_config(s.win, frame)
      -- Pin the float's internal view to the frame's slice; shift only if the
      -- cursor sits deeper than the slice can show (giant-overflow fallback).
      -- The FRAME's slice (not the shifted fallback) is what sync_view measures
      -- against, so nvim's transient float auto-scroll can't mask violations.
      --
      -- `s.internal_top` overrides it: for a block taller than the window the
      -- float's own view is the only thing that can express the scroll position
      -- (see sync_step), so it must survive a re-render.
      if s.internal_top then
        internal_topline = math.max(1, math.min(s.internal_top, math.max(1, #s.rendered.lines - frame.height + 1)))
      end
      s.pinned_topline = internal_topline or 1
      local it = internal_topline or 1
      local cr = vim.api.nvim_win_get_cursor(s.win)[1]
      if cr > it + frame.height - 1 then
        it = cr - frame.height + 1
      elseif cr < it then
        it = cr
      end
      vim.api.nvim_win_call(s.win, function()
        vim.fn.winrestview({ topline = it })
      end)
    end
    if keep_cell then
      local row, range = find_cell_line(s.rendered, keep_cell.source_lnum, keep_cell.index)
      if row then
        pcall(vim.api.nvim_win_set_cursor, s.win, { row, range.start_col + 1 })
      end
    end
  end
end

-- Map a focus-buffer cursor position to a byte offset in the cell's logical
-- text: prior wrapped segments count their full length plus the collapsed
-- break space; within the segment, subtract the cell padding. Exact for plain
-- text; inline markup shifts it slightly and the editor clamps.
local function cursor_cell_offset(s, row, col, index, line_obj)
  local offset = 0
  for r, lo in ipairs(s.rendered.line_objects) do
    if lo.source_lnum == line_obj.source_lnum and lo.cells and lo.cells[index] then
      local range = lo.cells[index]
      local slice = lo.text:sub(range.start_col + 1, range.end_col)
      local seg = vim.trim(slice)
      if r == row then
        local content_first = slice:find("%S") or 2
        local rel = (col - range.start_col) - (content_first - 1)
        return offset + math.max(0, math.min(rel, #seg))
      end
      offset = offset + #seg + 1
    end
  end
  return 0
end

-- Open the in-place cell editor for (lnum, index) with edit_cell options.
local function open_editor(s, lnum, index, edit_opts)
  local first_row, range = find_cell_line(s.rendered, lnum, index)
  if not first_row then
    return
  end
  local text = s.rendered.line_objects[first_row].text
  -- The focus float may have its own number column; cell screen positions
  -- shift right by its text offset.
  local focus_info = vim.fn.getwininfo(s.win)[1]
  local screen_col = vim.fn.strdisplaywidth(text:sub(1, range.start_col)) + (focus_info and focus_info.textoff or 0)
  local screen_width = vim.fn.strdisplaywidth(text:sub(range.start_col + 1, range.end_col))
  local height = cell_block_height(s.rendered, lnum)
  local keep = { source_lnum = lnum, index = index }

  s.editing = true
  require("markdown-table-wrap.edit").edit_cell({
    source_buf = s.source_buf,
    lnum = lnum,
    cell_index = index,
    live = true,
    offset = edit_opts.offset,
    insert = edit_opts.insert,
    truncate = edit_opts.truncate,
    delete_range = edit_opts.delete_range,
    position = {
      relative = "win",
      win = s.win,
      row = first_row - 1,
      col = screen_col,
      width = math.max(5, screen_width),
      height = math.min(12, math.max(1, height)),
    },
    on_live_update = function()
      -- Re-render behind the editor so the table reshapes as you type.
      if state == s then
        refresh()
      end
    end,
    on_close = function()
      if state ~= s then
        return
      end
      s.editing = false
      refresh(keep)
      if vim.api.nvim_win_is_valid(s.win) then
        vim.api.nvim_set_current_win(s.win)
      end
    end,
  })
end

--- opts.insert / opts.truncate are forwarded to edit_cell; the cursor's
--- position inside the rendered cell is translated to a text offset so i/a/C
--- act at the visual spot, like the cell were ordinary buffer text.
function M.edit_current_cell(opts)
  opts = opts or {}
  local s = state
  if not s then
    return
  end

  local row, col = unpack(vim.api.nvim_win_get_cursor(s.win))
  local index, _, line_obj = cell_at(s.rendered, row, col)
  if not index or not line_obj.source_lnum then
    vim.notify("MarkdownTableWrap: not on a table cell.", vim.log.levels.INFO)
    return
  end

  local offset = opts.whole and 0 or cursor_cell_offset(s, row, col, index, line_obj)
  open_editor(s, line_obj.source_lnum, index, {
    offset = offset,
    insert = opts.insert,
    truncate = opts.truncate,
  })
end

-- Reverse of cursor_cell_offset: byte offset in the cell's logical text back
-- to a focus-buffer (row, col), for keeping the cursor visually in place
-- after write-through edits.
local function offset_to_cursor(s, source_lnum, index, offset)
  local remaining = math.max(0, offset)
  for r, lo in ipairs(s.rendered.line_objects) do
    if lo.source_lnum == source_lnum and lo.cells and lo.cells[index] then
      local range = lo.cells[index]
      local slice = lo.text:sub(range.start_col + 1, range.end_col)
      local seg = vim.trim(slice)
      local content_first = slice:find("%S") or 2
      if remaining <= #seg then
        return r, range.start_col + (content_first - 1) + math.min(remaining, math.max(0, #seg - 1))
      end
      remaining = remaining - #seg - 1
    end
  end
  return nil
end

local function utf8_len_at(str, byte_offset)
  local ch = str:sub(byte_offset + 1):match("^[%z\1-\127\194-\244][\128-\191]*")
  return ch and #ch or 0
end

-- Read the cell under the focus cursor, apply fn(text, offset, count) →
-- new_text[, new_offset], write the result through to the source, re-render,
-- and put the cursor back at the corresponding visual position. fn returning
-- nil aborts. Divider lines no-op with a notice.
local function transform_cell(fn)
  local s = state
  if not s then
    return
  end

  local row, col = unpack(vim.api.nvim_win_get_cursor(s.win))
  local index, _, line_obj = cell_at(s.rendered, row, col)
  if not index or not line_obj.source_lnum then
    vim.notify("MarkdownTableWrap: not on a table cell.", vim.log.levels.INFO)
    return
  end

  local edit_mod = require("markdown-table-wrap.edit")
  local nav = require("markdown-table-wrap.nav")
  local lnum = line_obj.source_lnum
  local offset = cursor_cell_offset(s, row, col, index, line_obj)

  local line = vim.api.nvim_buf_get_lines(s.source_buf, lnum - 1, lnum, false)[1] or ""
  local span = nav.spans(line)[index]
  if not span then
    return
  end
  local text = edit_mod.unescape_pipes(vim.trim(line:sub(span.start_col + 1, span.end_col)))
  offset = math.min(offset, #text)

  local new_text, new_offset = fn(text, offset, vim.v.count1)
  if new_text == nil then
    return
  end

  if new_text ~= text then
    edit_mod.undo_break(s.source_buf)
    vim.api.nvim_buf_set_text(
      s.source_buf,
      lnum - 1,
      span.start_col,
      lnum - 1,
      span.end_col,
      { edit_mod.escape_pipes(new_text) }
    )
    refresh()
    if state ~= s then
      return
    end
  end

  local r2, c2 = offset_to_cursor(s, lnum, index, math.max(0, math.min(new_offset or offset, #new_text)))
  if r2 and vim.api.nvim_win_is_valid(s.win) then
    pcall(vim.api.nvim_win_set_cursor, s.win, { r2, c2 })
  end
end

-- Operator support (c/d with any motion or text object, visual c/d/x): vim
-- resolves the region natively via g@, we clamp it to the cell under the
-- start position and apply. Regions spilling past the cell clamp to its end;
-- linewise regions mean the whole cell.
local pending_op = nil

local function apply_range_op(op, r1, c1, r2, c2, linewise)
  local s = state
  if not s then
    return
  end

  local index, _, lo = cell_at(s.rendered, r1, c1)
  if not index or not lo.source_lnum then
    vim.notify("MarkdownTableWrap: not on a table cell.", vim.log.levels.INFO)
    return
  end

  local edit_mod = require("markdown-table-wrap.edit")
  local nav = require("markdown-table-wrap.nav")
  local lnum = lo.source_lnum
  local line = vim.api.nvim_buf_get_lines(s.source_buf, lnum - 1, lnum, false)[1] or ""
  local span = nav.spans(line)[index]
  if not span then
    return
  end
  local text = edit_mod.unescape_pipes(vim.trim(line:sub(span.start_col + 1, span.end_col)))

  local from, to
  if linewise then
    from, to = 0, #text
  else
    from = math.min(cursor_cell_offset(s, r1, c1, index, lo), #text)
    local index2, _, lo2 = cell_at(s.rendered, r2, c2)
    if index2 == index and lo2 and lo2.source_lnum == lnum then
      local o2 = math.min(cursor_cell_offset(s, r2, c2, index2, lo2), #text)
      to = math.min(o2 + math.max(1, utf8_len_at(text, o2)), #text)
    else
      -- Motion left the cell (c$, selection over the border): clamp.
      to = #text
    end
    if to < from then
      from, to = to, from
    end
  end

  vim.fn.setreg('"', text:sub(from + 1, to))

  if op == "delete" then
    local new_text = text:sub(1, from) .. text:sub(to + 1)
    edit_mod.undo_break(s.source_buf)
    vim.api.nvim_buf_set_text(
      s.source_buf,
      lnum - 1,
      span.start_col,
      lnum - 1,
      span.end_col,
      { edit_mod.escape_pipes(new_text) }
    )
    refresh()
    if state ~= s then
      return
    end
    local r3, c3 = offset_to_cursor(s, lnum, index, math.min(from, math.max(0, #new_text - 1)))
    if r3 and vim.api.nvim_win_is_valid(s.win) then
      pcall(vim.api.nvim_win_set_cursor, s.win, { r3, c3 })
    end
    return
  end

  -- change — deferred: the g@ opfunc runs under textlock where opening a
  -- window is forbidden.
  vim.schedule(function()
    if state == s then
      open_editor(s, lnum, index, {
        offset = from,
        insert = "at_offset",
        delete_range = { from, to },
      })
    end
  end)
end

function M._operator(motion_type)
  local s = state
  local op = pending_op
  pending_op = nil
  if not s or not op then
    return
  end
  if motion_type == "block" then
    vim.notify("MarkdownTableWrap: blockwise editing is not supported.", vim.log.levels.INFO)
    return
  end

  local sp = vim.api.nvim_buf_get_mark(s.buf, "[")
  local ep = vim.api.nvim_buf_get_mark(s.buf, "]")
  apply_range_op(op, sp[1], sp[2], ep[1], ep[2], motion_type == "line")
end

-- Forward undo/redo to the document and re-render in place; the cursor stays
-- at the same visual spot (clamped if the table shrank).
local function undo_redo(key)
  local s = state
  if not s then
    return
  end

  local row, col = unpack(vim.api.nvim_win_get_cursor(s.win))
  vim.api.nvim_buf_call(s.source_buf, function()
    vim.cmd("silent! normal! " .. vim.v.count1 .. key)
  end)
  refresh()
  if state == s and vim.api.nvim_win_is_valid(s.win) then
    local last = vim.api.nvim_buf_line_count(s.buf)
    pcall(vim.api.nvim_win_set_cursor, s.win, { math.min(row, last), col })
  end
end

-- Rebuild every source line of the table through mutate(cells, is_separator)
-- and write them back in ONE set_lines call, so the whole column operation is
-- a single native undo step.
local function rebuild_columns(mutate)
  local s = state
  if not s then
    return
  end

  local nav = require("markdown-table-wrap.nav")
  local edit_mod = require("markdown-table-wrap.edit")
  local info = s.table_info
  local new_lines = {}

  for lnum = info.start_lnum, info.end_lnum do
    local line = vim.api.nvim_buf_get_lines(s.source_buf, lnum - 1, lnum, false)[1] or ""
    local cells = {}
    for _, sp in ipairs(nav.spans(line)) do
      table.insert(cells, vim.trim(line:sub(sp.start_col + 1, sp.end_col)))
    end
    mutate(cells, lnum == info.separator_lnum)
    for i, c in ipairs(cells) do
      if c == "" then
        cells[i] = " "
      end
    end
    table.insert(new_lines, "| " .. table.concat(cells, " | ") .. " |")
  end

  edit_mod.undo_break(s.source_buf)
  vim.api.nvim_buf_set_lines(s.source_buf, info.start_lnum - 1, info.end_lnum, false, new_lines)
  refresh()
end

local function current_column(s)
  local row, col = unpack(vim.api.nvim_win_get_cursor(s.win))
  local index, _, lo = cell_at(s.rendered, row, col)
  return index, lo and lo.source_lnum
end

-- Add an empty column right (dir=1) or left (dir=-1) of the cursor's column.
local function add_column(dir)
  local s = state
  if not s then
    return
  end
  local index, slnum = current_column(s)
  local columns = #s.table_info.header
  index = index or (dir > 0 and columns or 1)
  local at = dir > 0 and index + 1 or index

  rebuild_columns(function(cells, is_separator)
    table.insert(cells, math.min(at, #cells + 1), is_separator and "---" or " ")
  end)

  if state == s then
    local row, range = find_cell_line(s.rendered, slnum or s.table_info.start_lnum, at)
    if row then
      pcall(vim.api.nvim_win_set_cursor, s.win, { row, range.start_col + 1 })
    end
  end
end

local function delete_column()
  local s = state
  if not s then
    return
  end
  local index, slnum = current_column(s)
  if not index then
    vim.notify("MarkdownTableWrap: not on a table column.", vim.log.levels.INFO)
    return
  end
  if #s.table_info.header <= 1 then
    vim.notify("MarkdownTableWrap: cannot delete the last column.", vim.log.levels.INFO)
    return
  end

  rebuild_columns(function(cells)
    if #cells >= index then
      table.remove(cells, index)
    end
  end)

  if state == s then
    local keep = math.min(index, #s.table_info.header)
    local row, range = find_cell_line(s.rendered, slnum or s.table_info.start_lnum, keep)
    if row then
      pcall(vim.api.nvim_win_set_cursor, s.win, { row, range.start_col + 1 })
    end
  end
end

-- Insert an empty row into the source below (dir=1) or above (dir=-1) the
-- cursor's row, then land on its first cell.
local function open_row(dir)
  local s = state
  if not s then
    return
  end

  local row, col = unpack(vim.api.nvim_win_get_cursor(s.win))
  local index, _, line_obj = cell_at(s.rendered, row, col)
  local lnum = line_obj and line_obj.source_lnum
  if not lnum then
    vim.notify("MarkdownTableWrap: not on a table row.", vim.log.levels.INFO)
    return
  end
  -- Never insert between header and separator.
  if lnum <= s.table_info.separator_lnum then
    lnum = s.table_info.separator_lnum
    if dir < 0 then
      vim.notify("MarkdownTableWrap: cannot add a row above the header.", vim.log.levels.INFO)
      return
    end
  end

  local columns = #s.table_info.header
  local empty = "|" .. string.rep("   |", columns)
  local at = dir > 0 and lnum or lnum - 1
  require("markdown-table-wrap.edit").undo_break(s.source_buf)
  vim.api.nvim_buf_set_lines(s.source_buf, at, at, false, { empty })
  refresh()
  if state == s then
    local r2, range = find_cell_line(s.rendered, at + 1, 1)
    if r2 then
      pcall(vim.api.nvim_win_set_cursor, s.win, { r2, range.start_col + 1 })
    end
  end
end

-- How many screen rows this table occupies once rendered. Used by screen-row
-- scrolling to decide whether a motion lands inside the table or clears it.
function M.rendered_height(table_info, source_win)
  source_win = source_win or vim.api.nvim_get_current_win()
  local rendered = rendered_for(source_win, table_info, require("markdown-table-wrap").config)
  return #rendered.lines
end

-- Open focus mode on `table_info` with the cursor on rendered row `row`.
-- `screen_row`, when given, is the window row that rendered row must land on —
-- a caller that already knows where the cursor belongs (screen-row scrolling)
-- rather than leaving it to be derived from the previous position.
function M.enter_at(table_info, row, screen_row)
  if M.is_open() then
    M.close(false)
  end
  entry_row = row
  entry_screen_row = screen_row
  suppressed[vim.api.nvim_get_current_buf()] = nil
  pcall(vim.api.nvim_win_set_cursor, 0, { table_info.start_lnum, 0 })
  M.focus()
  entry_row = nil
  entry_screen_row = nil
end

function M.focus()
  if M.is_open() then
    M.close(true)
    return
  end

  local mtw = require("markdown-table-wrap")
  local parser = require("markdown-table-wrap.parser")
  local nav = require("markdown-table-wrap.nav")

  local source_buf = vim.api.nvim_get_current_buf()
  local source_win = vim.api.nvim_get_current_win()
  local lnum, col = unpack(vim.api.nvim_win_get_cursor(0))
  local info, err = parser.parse_at_cursor(source_buf, lnum)
  if not info then
    vim.notify(err or "MarkdownTableWrap: cursor is not inside a Markdown pipe table.", vim.log.levels.INFO)
    return
  end

  local config = mtw.config
  local rendered = rendered_for(source_win, info, config)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, ("mtw-table://%d/%d"):format(source_buf, info.start_lnum))
  -- acwrite so :w in the focus float writes the underlying document.
  vim.bo[buf].buftype = "acwrite"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "markdown-table-wrap"
  fill_buffer(buf, rendered, config)
  vim.bo[buf].modified = false

  -- When the source window shows line numbers, the float grows its own
  -- relative-number column, shifted left to cover the source one: numbers then
  -- align with RENDERED rows, so Nj inside the table means exactly N presses.
  local wininfo = vim.fn.getwininfo(source_win)[1]
  local textoff = wininfo and wininfo.textoff or 0
  local want_numbers = textoff > 0 and (vim.wo[source_win].number or vim.wo[source_win].relativenumber)
  if not want_numbers then
    textoff = 0
  end

  -- Under the conceal_lines renderer the table's source lines have zero height,
  -- so the cursor arriving inside the table sits — as far as Neovim is
  -- concerned — just *after* the whole rendered block, and the source view has
  -- already scrolled past it by the time we get control. Re-pin the view on the
  -- block's anchor whenever its first row is off screen; the lockstep sync
  -- below then scrolls down to wherever the entry cell actually is.
  -- Scrolloff would make background cursor-tracking (and boundary exits)
  -- scroll the document early, dragging it out from under the float. Zero it
  -- for both windows while focus is open; restored on close. This has to happen
  -- BEFORE the view is pinned below, or scrolloff drags the pinned topline back
  -- up by its own margin.
  local saved_scrolloff = vim.api.nvim_get_option_value("scrolloff", { win = source_win, scope = "local" })
  vim.api.nvim_set_option_value("scrolloff", 0, { win = source_win, scope = "local" })
  -- smoothscroll lets the source scroll by screen line through the virt_lines
  -- blocks of other rendered tables, keeping lockstep sync exact.
  local saved_smooth = vim.api.nvim_get_option_value("smoothscroll", { win = source_win, scope = "local" })
  vim.api.nvim_set_option_value("smoothscroll", true, { win = source_win, scope = "local" })

  local block_anchor, block_above = require("markdown-table-wrap.inline").block_anchor(source_buf, info, config)
  local pin_topline = info.start_lnum > 1 and info.start_lnum - 1 or info.start_lnum

  -- Adjacent-line arrival (j from above / k from below) lands on the top or
  -- bottom border — one step per rendered line, like the border were an
  -- ordinary line. Everything else (search, G, explicit focus) maps to the
  -- exact cell AND column, so e.g. a search match is under the cursor.
  --
  -- Resolved BEFORE the float is opened: where the block gets drawn depends on
  -- which rendered row the cursor is about to occupy.
  local hint = entry_hint
  entry_hint = nil
  local want_row = entry_row
  entry_row = nil
  local source_line = vim.api.nvim_buf_get_lines(source_buf, lnum - 1, lnum, false)[1] or ""
  local index, spans = nav.cell_index_at(source_line, col)
  local target_row, target_col
  if want_row then
    -- Explicit rendered row (screen-row scrolling): land exactly there so a
    -- half-page motion covers the same distance inside the table as outside.
    target_row, target_col = math.max(1, math.min(#rendered.lines, want_row)), 0
  elseif hint then
    target_row, target_col = hint == "above" and 1 or #rendered.lines, 0
    if index then
      local _, range = find_cell_line(rendered, lnum, index)
      if range then
        target_col = range.start_col + 1
      end
    end
  elseif index then
    local span = spans[index]
    local off = span and math.max(0, math.min(col - span.start_col, span.end_col - span.start_col)) or 0
    target_row, target_col = offset_to_cursor({ rendered = rendered }, lnum, index, off)
  end
  if not target_row then
    for row, line_obj in ipairs(rendered.line_objects) do
      if line_obj.cells and line_obj.cells[1] then
        target_row, target_col = row, line_obj.cells[1].start_col + 1
        break
      end
    end
  end
  target_row, target_col = target_row or 1, target_col or 0

  -- Continuity: draw the block where the motion that brought the cursor here
  -- says it belongs, so arriving in a table does not shift the cursor's screen
  -- row. Without this the source window's own reveal-scroll decides — it has
  -- already run by now, the table's source lines being zero-height — and the
  -- view lurches by the block's height.
  local viewport = require("markdown-table-wrap.viewport")
  local prev = viewport.last(source_win)
  local want_screen = entry_screen_row
  local placed_block = false
  if block_anchor and (want_screen or (prev and prev.buf == source_buf)) then
    local win_h = vim.api.nvim_win_get_height(source_win)
    -- The window's own 'scrolloff' is zeroed above, so read the saved value.
    local so = saved_scrolloff >= 0 and saved_scrolloff or vim.go.scrolloff
    local margin = math.min(so, math.floor((win_h - 1) / 2))
    local want
    if want_screen then
      want = math.max(margin + 1, math.min(want_screen, win_h - margin))
    else
      local to_anchor = viewport.distance(source_win, source_buf, prev.lnum, block_anchor)
      -- Above-anchored blocks are drawn in the rows before the anchor's text;
      -- below-anchored ones start one row after it.
      local to_first = block_above and (to_anchor - #rendered.lines) or (to_anchor + 1)
      local delta = to_first + (target_row - 1)
      if math.abs(delta) >= win_h then
        want = math.floor(win_h / 2)
      else
        want = math.max(margin + 1, math.min(prev.row + delta, win_h - margin))
      end
    end
    placed_block = viewport.place_block(
      source_win,
      source_buf,
      info,
      #rendered.lines,
      want - (target_row - 1),
      config
    ) ~= nil

    if placed_block then
      -- Park the source cursor on a line with real height, and one that is
      -- ON SCREEN in the view just placed. Left on the table's zero-height
      -- lines Neovim scrolls past the whole block to "reveal" it the moment
      -- focus moves to the float; left on an off-screen line it scrolls to
      -- reveal that instead. Either way the placement is undone.
      -- The real cell is restored on exit (see M.close).
      local view = vim.api.nvim_win_call(source_win, vim.fn.winsaveview)
      local park = block_anchor
      if vim.fn.screenpos(source_win, park, 1).row == 0 and info.start_lnum > 1 then
        park = info.start_lnum - 1
      end
      pcall(vim.api.nvim_win_set_cursor, source_win, { park, 0 })
      vim.api.nvim_win_call(source_win, function()
        vim.fn.winrestview({ topline = view.topline, topfill = view.topfill, skipcol = view.skipcol })
      end)
    end
  end

  if block_anchor and not placed_block then
    local wtop = vim.fn.win_screenpos(source_win)[1]
    local top = block_top_row(source_win, info, rendered)
    if not top or top < wtop then
      -- Pin the view to the line just above the table, where the block's first
      -- row is drawn. Park the source cursor there too: a cursor left on a
      -- zero-height table line drags the view straight back past the block on
      -- the next redraw, undoing the pin. The real cell is restored on exit
      -- (see M.close).
      pcall(vim.api.nvim_win_set_cursor, source_win, { pin_topline, 0 })
      vim.api.nvim_win_call(source_win, function()
        vim.fn.winrestview({ topline = pin_topline, topfill = 0, skipcol = 0 })
      end)
    end
  end

  local frame, internal_topline = compute_frame(source_win, info, rendered, textoff)
  local open_cfg = vim.tbl_extend("force", frame, {
    style = "minimal",
    border = "none",
    zindex = 60,
  })
  local win = vim.api.nvim_open_win(buf, true, open_cfg)
  if want_numbers then
    vim.wo[win].number = true
    vim.wo[win].relativenumber = vim.wo[source_win].relativenumber
    vim.wo[win].numberwidth = math.max(2, math.min(20, textoff))
    vim.wo[win].signcolumn = "no"
  end

  vim.wo[win].scrolloff = 0

  state = {
    win = win,
    buf = buf,
    source_buf = source_buf,
    source_win = source_win,
    table_info = info,
    rendered = rendered,
    config = config,
    textoff = textoff,
    block_anchor = block_anchor,
    pin_topline = pin_topline,
    saved_scrolloff = saved_scrolloff,
    saved_smooth = saved_smooth,
    scrolloff = saved_scrolloff >= 0 and saved_scrolloff or vim.go.scrolloff,
    editing = false,
    syncing = false,
  }

  pcall(vim.api.nvim_win_set_cursor, win, { target_row, target_col })

  state.pinned_topline = internal_topline or 1
  -- Top-clipped frame: show exactly the rows the overlay was showing. If the
  -- entry cursor lands outside this slice, the sync pass fired right below
  -- scrolls the SOURCE until the margins hold — never clamp the cursor away
  -- from where it belongs (e.g. the bottom border on entry from below).
  if internal_topline then
    vim.api.nvim_win_call(win, function()
      vim.fn.winrestview({ topline = internal_topline })
    end)
  end

  local s = state
  -- q is the deliberate escape hatch to the raw source (suppresses re-entry
  -- until the cursor leaves the table). No <Esc> map: habitual Esc presses
  -- should not silently drop out of the rendered view.
  vim.keymap.set("n", "q", function()
    M.close(true)
  end, { buffer = buf, nowait = true, silent = true, desc = "Leave table focus (raw source)" })

  local edit_keys = {
    ["<CR>"] = {},
    i = { insert = "at_offset" },
    a = { insert = "after_offset" },
    I = { insert = "start" },
    A = { insert = "append" },
    C = { insert = "append", truncate = true },
    cc = { insert = "start", truncate = true, whole = true },
    S = { insert = "start", truncate = true, whole = true },
  }
  for lhs, edit_opts in pairs(edit_keys) do
    vim.keymap.set("n", lhs, function()
      M.edit_current_cell(edit_opts)
    end, { buffer = buf, nowait = true, silent = true, desc = "Edit cell under cursor" })
  end

  -- Write-through cell operators: act on the logical cell text at the visual
  -- cursor position, like the cell were an ordinary line.
  vim.keymap.set("n", "x", function()
    transform_cell(function(text, offset, count)
      if offset >= #text then
        return nil
      end
      local stop = offset
      for _ = 1, count do
        stop = stop + utf8_len_at(text, stop)
      end
      local new = text:sub(1, offset) .. text:sub(stop + 1)
      return new, math.min(offset, math.max(0, #new - 1))
    end)
  end, { buffer = buf, nowait = true, silent = true, desc = "Delete char in cell" })

  vim.keymap.set("n", "X", function()
    transform_cell(function(text, offset, count)
      local start = offset
      for _ = 1, count do
        local prev = text:sub(1, start):match("[%z\1-\127\194-\244][\128-\191]*$")
        if not prev then
          break
        end
        start = start - #prev
      end
      return text:sub(1, start) .. text:sub(offset + 1), start
    end)
  end, { buffer = buf, nowait = true, silent = true, desc = "Delete char before cursor in cell" })

  vim.keymap.set("n", "r", function()
    local ok, char = pcall(vim.fn.getcharstr)
    if not ok or char == "" or char == vim.api.nvim_replace_termcodes("<Esc>", true, false, true) then
      return
    end
    transform_cell(function(text, offset)
      if offset >= #text then
        return nil
      end
      local len = utf8_len_at(text, offset)
      return text:sub(1, offset) .. char .. text:sub(offset + len + 1), offset
    end)
  end, { buffer = buf, nowait = true, silent = true, desc = "Replace char in cell" })

  vim.keymap.set("n", "~", function()
    transform_cell(function(text, offset)
      if offset >= #text then
        return nil
      end
      local len = utf8_len_at(text, offset)
      local ch = text:sub(offset + 1, offset + len)
      local swapped = ch:upper()
      if swapped == ch then
        swapped = ch:lower()
      end
      return text:sub(1, offset) .. swapped .. text:sub(offset + len + 1), offset + len
    end)
  end, { buffer = buf, nowait = true, silent = true, desc = "Toggle case in cell" })

  vim.keymap.set("n", "D", function()
    transform_cell(function(text, offset)
      return text:sub(1, offset), math.max(0, offset - 1)
    end)
  end, { buffer = buf, nowait = true, silent = true, desc = "Delete to end of cell" })

  vim.keymap.set("n", "dd", function()
    transform_cell(function()
      return "", 0
    end)
  end, { buffer = buf, nowait = true, silent = true, desc = "Clear cell" })

  vim.keymap.set("n", "yy", function()
    transform_cell(function(text)
      vim.fn.setreg('"', text)
      vim.notify("MarkdownTableWrap: cell yanked.", vim.log.levels.INFO)
      return nil
    end)
  end, { buffer = buf, nowait = true, silent = true, desc = "Yank cell text" })

  for lhs, after in pairs({ p = true, P = false }) do
    vim.keymap.set("n", lhs, function()
      local reg = (vim.fn.getreg('"') or ""):gsub("%s*\n%s*", " ")
      if reg == "" then
        return
      end
      transform_cell(function(text, offset)
        local at = offset
        if after and offset < #text then
          at = offset + utf8_len_at(text, offset)
        end
        return text:sub(1, at) .. reg .. text:sub(at + 1), at + #reg - 1
      end)
    end, { buffer = buf, nowait = true, silent = true, desc = "Paste into cell" })
  end

  vim.keymap.set("n", "u", function()
    undo_redo("u")
  end, { buffer = buf, nowait = true, silent = true, desc = "Undo (document)" })
  vim.keymap.set("n", "<C-r>", function()
    undo_redo(vim.api.nvim_replace_termcodes("<C-r>", true, false, true))
  end, { buffer = buf, nowait = true, silent = true, desc = "Redo (document)" })

  vim.keymap.set("n", "o", function()
    open_row(1)
  end, { buffer = buf, nowait = true, silent = true, desc = "New row below" })
  vim.keymap.set("n", "O", function()
    open_row(-1)
  end, { buffer = buf, nowait = true, silent = true, desc = "New row above" })
  vim.keymap.set("n", "go", function()
    add_column(1)
  end, { buffer = buf, nowait = true, silent = true, desc = "New column right" })
  vim.keymap.set("n", "gO", function()
    add_column(-1)
  end, { buffer = buf, nowait = true, silent = true, desc = "New column left" })
  vim.keymap.set("n", "dc", function()
    delete_column()
  end, { buffer = buf, silent = true, desc = "Delete column" })

  -- Lockstep scrolling: the float never scrolls on its own. Whenever the
  -- focus cursor's on-screen row would violate the user's scrolloff margin,
  -- the SOURCE view scrolls by the deficit and the frame re-syncs — document
  -- and table move as one, exactly like native cursor motion.
  local function sync_step()
    local viewport = require("markdown-table-wrap.viewport")
    local win_h = vim.api.nvim_win_get_height(s.source_win)
    local wtop = vim.fn.win_screenpos(s.source_win)[1]
    local rows = #s.rendered.lines
    local top = block_top_row(s.source_win, s.table_info, s.rendered)
    if not top then
      return false
    end

    -- Everything below is a 1-based screen row within the source window. The
    -- float's first row is drawn at `frame_row + 1`, and it shows the block
    -- starting at its own topline, so both terms are needed: with a tall block
    -- the float is scrolled internally and the block's top is off-screen.
    local block_top = top - wtop + 1
    local frame_row = math.max(0, block_top - 1)
    local internal_top = s.pinned_topline or 1
    local cursor_row = vim.api.nvim_win_get_cursor(s.win)[1]
    local screen_row = frame_row + (cursor_row - internal_top + 1)

    local margin = math.min(s.scrolloff, math.floor((win_h - 1) / 2))
    local want = math.max(margin + 1, math.min(screen_row, win_h - margin))
    if want == screen_row then
      return false
    end

    local target = block_top + (want - screen_row)

    -- A block taller than the window cannot be positioned freely by the source:
    -- 'topfill' is capped at the window height, so the reachable views are
    -- "block starts at row 2 or below" and "the block's last win_h rows", with a
    -- hole between. Asking for an interior offset silently snaps to one end,
    -- which is what left the cursor against the window edge with no margin.
    --
    -- So the source scrolls the document away until the block starts at row 2 —
    -- the table taking over the window, as it should — and past that the float's
    -- own view, which has no such hole, carries the scroll.
    if rows >= win_h and target < 2 then
      local height = vim.api.nvim_win_get_height(s.win)
      local limit = math.max(1, rows - height + 1)
      local target_top = math.max(1, math.min(cursor_row + frame_row + 1 - want, limit))
      if target_top ~= internal_top then
        s.internal_top = target_top
        s.pinned_topline = target_top
        vim.api.nvim_win_call(s.win, function()
          vim.fn.winrestview({ topline = target_top })
        end)
        return true
      end
      -- Pinned against an edge of the block: the document behind has to move
      -- now, so fall through to placing the source. `s.internal_top` stays put
      -- — it is what `screen_row` above was measured against, and dropping it
      -- here would let the next re-render recompute the float's view and snap
      -- it, undoing the placement that is about to happen.
    elseif rows < win_h then
      -- Block fits: the source can express every position, so the float always
      -- shows it from the top.
      s.internal_top = nil
    end

    -- Drive (topline, topfill) straight to the answer instead of scrolling the
    -- source with <C-e>/<C-y>. Those cannot express a view part-way into the
    -- block — Neovim renormalises to show it whole — which is the jump this
    -- whole mechanism exists to remove.
    --
    -- The target is bounded so the document never scrolls out from under the
    -- float: while focus is open the float is showing this table, so the block
    -- keeps at least one row on screen at either edge.
    target = math.max(2 - rows, math.min(target, win_h))
    local got = viewport.place_block(s.source_win, s.source_buf, s.table_info, rows, target, s.config)
    refresh()
    -- Converged once the block could not actually move (buffer edge, or the
    -- representation has no row left to give).
    return got ~= nil and got ~= block_top
  end

  local function sync_view()
    if state ~= s or s.editing or s.syncing or not vim.api.nvim_win_is_valid(s.win) then
      return
    end
    s.syncing = true
    for _ = 1, 4 do
      local moved = sync_step()
      if not moved or state ~= s then
        break
      end
    end
    if state == s then
      s.syncing = false
    end
  end

  -- Track the focus cursor's cell back onto the source window's cursor. The
  -- source number column is visible left of the borderless float, so its
  -- relative numbers keep recomputing against the row we're actually on —
  -- lines below the table show truthful Nj targets while inside the table.
  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = buf,
    callback = function()
      if state ~= s or not vim.api.nvim_win_is_valid(s.source_win) then
        return
      end
      sync_view()
      local row, fcol = unpack(vim.api.nvim_win_get_cursor(s.win))
      local slnum
      if row >= #s.rendered.line_objects then
        slnum = s.table_info.end_lnum
      else
        for r = row, 1, -1 do
          local lo = s.rendered.line_objects[r]
          if lo and lo.source_lnum then
            slnum = lo.source_lnum
            break
          end
        end
      end
      slnum = slnum or s.table_info.start_lnum

      -- Track the column too, not just the line: forwarded searches (n/N)
      -- continue from the real position instead of re-finding the same match.
      local scol = 0
      local index, _, lo = cell_at(s.rendered, row, fcol)
      if index and lo.source_lnum == slnum then
        local off = cursor_cell_offset(s, row, fcol, index, lo)
        local nav = require("markdown-table-wrap.nav")
        local sline = vim.api.nvim_buf_get_lines(s.source_buf, slnum - 1, slnum, false)[1] or ""
        local sp2 = nav.spans(sline)[index]
        if sp2 then
          scol = math.min(sp2.start_col + off, math.max(0, #sline - 1))
        end
      end
      -- Clamp to the source window's current view: nvim_win_set_cursor
      -- auto-scrolls to reveal off-view lines, which would drag the document
      -- behind the float. Scrolling is owned by reveal_above/exit paths.
      local w0, w1 = unpack(vim.api.nvim_win_call(s.source_win, function()
        return { vim.fn.line("w0"), vim.fn.line("w$") }
      end))
      local clamped = math.max(w0, math.min(slnum, w1))
      if clamped ~= slnum then
        scol = 0
      end
      -- Even a clamped line can move the view: the table's source lines have
      -- zero height, so Neovim "reveals" one by scrolling past the whole
      -- rendered block. That drift is invisible until the next sync measures
      -- the block against it and yanks the float. Put the view back.
      local before = vim.api.nvim_win_call(s.source_win, vim.fn.winsaveview)
      pcall(vim.api.nvim_win_set_cursor, s.source_win, { clamped, scol })
      vim.api.nvim_win_call(s.source_win, function()
        local now = vim.fn.winsaveview()
        if now.topline ~= before.topline or (now.topfill or 0) ~= (before.topfill or 0) then
          vim.fn.winrestview({ topline = before.topline, topfill = before.topfill, skipcol = before.skipcol })
        end
      end)
      -- Non-current-window cursor moves may not repaint its number column.
      pcall(vim.api.nvim__redraw, { win = s.source_win, valid = true })
    end,
  })
  vim.api.nvim_exec_autocmds("CursorMoved", { buffer = buf })

  -- Document search cycles seamlessly through and out of the table: forward
  -- the search keys to the source window (cursor already tracked there); a
  -- match inside a table auto-enters focus at that cell, a match outside just
  -- lands there.
  for _, lhs in ipairs({ "/", "?", "n", "N", "*", "#" }) do
    vim.keymap.set("n", lhs, function()
      M.close(false)
      -- "i": insert before pending typeahead, so keys typed right after the
      -- trigger (e.g. the search pattern) still land after it.
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(lhs, true, false, true), "ni", false)
    end, { buffer = buf, nowait = true, silent = true, desc = "Search document" })
  end

  -- Real operators: c/d set operatorfunc and let vim resolve the motion or
  -- text object natively (cw, ciw, caw, c$, df., counts…), then the region is
  -- clamped to the cell. dd/cc above still win by longest-match.
  for lhs, opname in pairs({ c = "change", d = "delete" }) do
    vim.keymap.set("n", lhs, function()
      pending_op = opname
      vim.o.operatorfunc = "v:lua.require'markdown-table-wrap.view'._operator"
      return "g@"
    end, { buffer = buf, expr = true, silent = true, desc = "Cell " .. opname .. " operator" })
  end

  -- Native cw/cW act like ce/cE; g@ doesn't get that special case, so restore
  -- it while our change operator is pending.
  for lhs, rhs in pairs({ w = "e", W = "E" }) do
    vim.keymap.set("o", lhs, function()
      if vim.v.operator == "g@" and pending_op == "change" then
        return rhs
      end
      return lhs
    end, { buffer = buf, expr = true, silent = true })
  end

  -- Visual c/d/x apply to the selection, clamped to one cell.
  for lhs, opname in pairs({ c = "change", d = "delete", x = "delete" }) do
    vim.keymap.set("x", lhs, function()
      local mode = vim.fn.mode()
      if mode == "\22" then
        vim.notify("MarkdownTableWrap: blockwise editing is not supported.", vim.log.levels.INFO)
        return
      end
      local a = vim.fn.getpos("v")
      local b = vim.fn.getpos(".")
      if a[2] > b[2] or (a[2] == b[2] and a[3] > b[3]) then
        a, b = b, a
      end
      vim.cmd("normal! \27")
      apply_range_op(opname, a[2], a[3] - 1, b[2], b[3] - 1, mode == "V")
    end, { buffer = buf, nowait = true, silent = true, desc = "Cell " .. opname .. " selection" })
  end

  -- Unsupported edits: quiet notice instead of E21 'not modifiable' errors.
  -- `s` is deliberately NOT shadowed: flash.nvim owns it, and flash jumps
  -- work natively on the rendered table text inside this float.
  vim.keymap.set("n", "J", function()
    vim.notify("MarkdownTableWrap: editing is per-cell; use cc / dd / i on a cell.", vim.log.levels.INFO)
  end, { buffer = buf, silent = true })
  for _, lhs in ipairs({ "r", "p" }) do
    vim.keymap.set("x", lhs, function()
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
      vim.notify("MarkdownTableWrap: editing is per-cell; use cc / i on a cell.", vim.log.levels.INFO)
    end, { buffer = buf, nowait = true, silent = true })
  end

  -- Sail through the table: j/k crossing the rendered edges exit past the
  -- table, spilling any remaining count into the document.
  for lhs, direction in pairs({ j = 1, ["<Down>"] = 1, k = -1, ["<Up>"] = -1 }) do
    vim.keymap.set("n", lhs, function()
      local count = vim.v.count1
      local row = vim.api.nvim_win_get_cursor(0)[1]
      local space = direction > 0 and vim.api.nvim_buf_line_count(buf) - row or row - 1
      if count > space then
        -- j/k advance the cursor's screen row with it, up to the margin.
        local screen = cursor_screen_row()
        exit_past(direction, count - space - 1, screen and (screen + direction * count))
      else
        vim.cmd("normal! " .. count .. (direction > 0 and "j" or "k"))
        sync_view()
      end
    end, { buffer = buf, nowait = true, silent = true, desc = "Move / exit table" })
  end

  -- Half-page / page motion counts RENDERED rows — the rows actually on screen
  -- — so a <C-u> inside the table covers the same visual distance as one in
  -- prose. Overshooting an edge spills the remainder into the document (same
  -- rule as j/k), so repeated presses walk out of the table and keep going
  -- instead of stalling against it. Forwarding these to the document, as this
  -- used to, is what made a tall table a dead end: Neovim cannot scroll a
  -- virt_lines block taller than the window.
  local function page_amount(full)
    local win_h = vim.api.nvim_win_get_height(s.source_win)
    if full then
      return math.max(1, win_h - 2)
    end
    local scroll = vim.api.nvim_get_option_value("scroll", { win = s.source_win, scope = "local" })
    return math.max(1, scroll > 0 and scroll or math.floor(win_h / 2))
  end
  for lhs, spec in pairs({
    ["<C-d>"] = { 1, false },
    ["<C-u>"] = { -1, false },
    ["<C-f>"] = { 1, true },
    ["<C-b>"] = { -1, true },
  }) do
    local direction, full = spec[1], spec[2]
    vim.keymap.set("n", lhs, function()
      local count = vim.v.count > 0 and vim.v.count or page_amount(full)
      local row = vim.api.nvim_win_get_cursor(0)[1]
      local space = direction > 0 and (vim.api.nvim_buf_line_count(buf) - row) or (row - 1)
      if count > space then
        -- Half/full page moves view and cursor together: the row is kept.
        exit_past(direction, count - space - 1, cursor_screen_row())
      else
        vim.cmd("normal! " .. count .. (direction > 0 and "j" or "k"))
        sync_view()
      end
    end, { buffer = buf, nowait = true, silent = true, desc = "Half page / page in table" })
  end

  -- Everything focus mode does NOT claim belongs to the document. Unmapped keys
  -- already behave (w, G, <C-w>… act natively on the rendered text), but a key
  -- with a *mapping* would run that mapping against the float: <S-l>
  -- (BufferLineCyclePrev/Next) swapped the float's own buffer for another file
  -- instead of switching buffers in the document window. So mirror every
  -- document mapping — global first, then the source buffer's own — into the
  -- float as "leave focus, replay the key". M.close(true) parks the cursor back
  -- on the matching source cell and suppresses auto-re-entry until it leaves
  -- the table, so the key lands in the source window exactly once.
  -- <Esc> is deliberately unmapped in focus mode (habitual presses should not
  -- drop out of the rendered view), so it must not be mirrored either.
  local focus_keys = { "<Esc>" }
  for _, m in ipairs(vim.api.nvim_buf_get_keymap(buf, "n")) do
    focus_keys[#focus_keys + 1] = m.lhs
  end
  local seen = {}
  local function forward_to_document(lhs)
    if lhs == "" or seen[lhs] then
      return
    end
    seen[lhs] = true
    for _, key in ipairs(focus_keys) do
      -- Skip focus mode's own keys, and any key sharing a prefix with one: the
      -- shorter of the two would go ambiguous and stall for 'timeoutlen' —
      -- e.g. the global `d<Space>` would delay every cell `d` operator.
      if lhs:sub(1, #key) == key or key:sub(1, #lhs) == lhs then
        return
      end
    end
    vim.keymap.set("n", lhs, function()
      -- Counts are consumed by this mapping, so replay them with the key.
      local count = vim.v.count > 0 and tostring(vim.v.count) or ""
      M.close(true)
      -- "m" (remappable) so lazy-load stubs and the real mapping both fire;
      -- "i" so keys typed straight after (an operator's motion) stay in order.
      vim.api.nvim_feedkeys(count .. vim.api.nvim_replace_termcodes(lhs, true, false, true), "mi", false)
      -- No `nowait`: these mirror the document's own map set, so let vim
      -- resolve prefixes exactly as it would outside the float (a mapped
      -- `<leader>x` must still wait on a `<leader>xx`).
    end, { buffer = buf, silent = true, desc = "Document mapping: " .. lhs })
  end
  for _, m in ipairs(vim.api.nvim_get_keymap("n")) do
    forward_to_document(m.lhs)
  end
  for _, m in ipairs(vim.api.nvim_buf_get_keymap(s.source_buf, "n")) do
    forward_to_document(m.lhs)
  end
  -- Document-scoped motions have no mapping to mirror, so name them: their
  -- subject is the FILE, not the table. gg/G inside focus mode were landing on
  -- the table's own first/last rendered row instead of the top/bottom of the
  -- markdown file — a rendered table is meant to stay out of the way of the
  -- plain-text document it lives in.
  for _, lhs in ipairs({ "gg", "G", "{", "}", "(", ")", "[[", "]]", "<C-o>", "<C-i>", "``", "''" }) do
    forward_to_document(lhs)
  end

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      if vim.api.nvim_buf_is_valid(s.source_buf) then
        vim.api.nvim_buf_call(s.source_buf, function()
          vim.cmd("silent write")
        end)
      end
      vim.bo[buf].modified = false
    end,
  })

  vim.api.nvim_create_autocmd("WinLeave", {
    buffer = buf,
    callback = function()
      if state == s and not s.editing then
        vim.schedule(function()
          if state == s and not s.editing then
            M.close(false)
          end
        end)
      end
    end,
  })
end

-- CursorMoved hook (installed when config.auto_focus is set): entering a
-- table's source lines in normal mode opens focus mode at the matching cell,
-- so the table is always navigated natively without an explicit trigger.
function M.try_auto_enter()
  if state or vim.api.nvim_get_mode().mode ~= "n" then
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local prev = last_lnum[bufnr]
  last_lnum[bufnr] = lnum

  local sup = suppressed[bufnr]
  if sup then
    if lnum >= sup[1] and lnum <= sup[2] then
      return
    end
    suppressed[bufnr] = nil
  end

  local line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
  if not line:find("|", 1, true) then
    return
  end

  local parser = require("markdown-table-wrap.parser")
  local info = parser.parse_at_cursor(bufnr, lnum)
  if not info then
    return
  end

  local hint = nil
  if prev and lnum == info.start_lnum and prev == info.start_lnum - 1 then
    hint = "above"
  elseif prev and lnum == info.end_lnum and prev == info.end_lnum + 1 then
    hint = "below"
  end

  vim.schedule(function()
    if state or vim.api.nvim_get_mode().mode ~= "n" then
      return
    end
    if vim.api.nvim_get_current_buf() ~= bufnr then
      return
    end
    local now = vim.api.nvim_win_get_cursor(0)[1]
    local current = vim.api.nvim_buf_get_lines(bufnr, now - 1, now, false)[1] or ""
    if current:find("|", 1, true) then
      entry_hint = hint
      M.focus()
    end
  end)
end

return M
