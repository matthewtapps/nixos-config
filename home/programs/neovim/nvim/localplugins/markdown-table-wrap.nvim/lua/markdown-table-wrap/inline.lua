local render = require("markdown-table-wrap.render")

local M = {}

local namespace = vim.api.nvim_create_namespace("markdown-table-wrap")
local saved_conceallevels = {}
local saved_concealcursors = {}
local saved_wraps = {}
local active_buffers = {}
local active_tables = {}
local active_configs = {}
local active_cells = {}
local view_offsets = {}

local function normalize_bufnr(bufnr)
  if not bufnr or bufnr == 0 then
    return vim.api.nvim_get_current_buf()
  end
  return bufnr
end

local border_chars = {
  ["╭"] = true,
  ["╮"] = true,
  ["╰"] = true,
  ["╯"] = true,
  ["┌"] = true,
  ["┐"] = true,
  ["└"] = true,
  ["┘"] = true,
  ["┬"] = true,
  ["┴"] = true,
  ["├"] = true,
  ["┤"] = true,
  ["┼"] = true,
  ["│"] = true,
  ["─"] = true,
  ["+"] = true,
  ["|"] = true,
  ["-"] = true,
}

local function iter_chars(text)
  return (text or ""):gmatch("[%z\1-\127\194-\244][\128-\191]*")
end

local function append_chunk(chunks, text, hl_group)
  if text == "" then
    return
  end

  local last = chunks[#chunks]
  if last and last[2] == hl_group then
    last[1] = last[1] .. text
  else
    table.insert(chunks, { text, hl_group })
  end
end

local function semantic_chunks(line, line_index)
  local chunks = {}
  local index = 1

  while index <= #line do
    local code_start = line:find("`", index, true)
    local link_start = line:find("%[.-%]%(.-%)", index)
    local special_start = nil
    local special_end = nil
    local special_hl = nil

    if code_start and (not link_start or code_start < link_start) then
      local code_end = line:find("`", code_start + 1, true)
      if code_end then
        special_start = code_start
        special_end = code_end
        special_hl = "MarkdownTableWrapCode"
      end
    elseif link_start then
      local start_col, end_col = line:find("%[.-%]%(.-%)", index)
      special_start = start_col
      special_end = end_col
      special_hl = "MarkdownTableWrapLink"
    end

    local plain_end = special_start and special_start - 1 or #line
    local plain = line:sub(index, plain_end)
    local buffer = ""
    for ch in iter_chars(plain) do
      local hl_group
      if border_chars[ch] then
        hl_group = "MarkdownTableWrapBorder"
      elseif line_index == 2 then
        hl_group = "MarkdownTableWrapHeader"
      else
        hl_group = "MarkdownTableWrapInline"
      end
      append_chunk(chunks, ch, hl_group)
      buffer = ""
    end

    if not special_start then
      break
    end

    append_chunk(chunks, line:sub(special_start, special_end), special_hl)
    index = special_end + 1
  end

  return chunks
end

local function chunks_from_line_object(line_obj, line_index)
  if type(line_obj) ~= "table" or not line_obj.chunks or #line_obj.chunks == 0 then
    return semantic_chunks(type(line_obj) == "table" and line_obj.text or line_obj, line_index)
  end

  local result = {}
  local cursor = 0
  local sorted = vim.deepcopy(line_obj.chunks)
  table.sort(sorted, function(a, b)
    return a.start_col < b.start_col
  end)

  for _, styled in ipairs(sorted) do
    if cursor < styled.start_col then
      vim.list_extend(result, semantic_chunks(line_obj.text:sub(cursor + 1, styled.start_col), line_index))
    end

    table.insert(result, {
      line_obj.text:sub(styled.start_col + 1, styled.end_col),
      styled.hl_group,
    })
    cursor = styled.end_col
  end

  if cursor < #line_obj.text then
    vim.list_extend(result, semantic_chunks(line_obj.text:sub(cursor + 1), line_index))
  end

  return result
end

-- Overlay chunks are contiguous {text, hl} pairs; to mark the active cell we
-- split chunks at the cell's byte boundaries and stack the active-cell group
-- on top of each covered slice (extmark virt_text accepts a list of groups).
local function with_active_hl(hl)
  local groups = {}
  if type(hl) == "table" then
    vim.list_extend(groups, hl)
  elseif hl then
    table.insert(groups, hl)
  end
  table.insert(groups, "MarkdownTableWrapActiveCell")
  return groups
end

local function highlight_range(chunks, range_start, range_end)
  local result = {}
  local offset = 0

  for _, chunk in ipairs(chunks) do
    local text, hl = chunk[1], chunk[2]
    local chunk_start, chunk_end = offset, offset + #text

    if chunk_end <= range_start or chunk_start >= range_end then
      table.insert(result, chunk)
    else
      local left = math.max(chunk_start, range_start) - chunk_start
      local right = math.min(chunk_end, range_end) - chunk_start
      if left > 0 then
        table.insert(result, { text:sub(1, left), hl })
      end
      table.insert(result, { text:sub(left + 1, right), with_active_hl(hl) })
      if right < #text then
        table.insert(result, { text:sub(right + 1), hl })
      end
    end

    offset = chunk_end
  end

  return result
end

local function apply_active_cell(chunks, line_obj, active)
  if
    not active
    or type(line_obj) ~= "table"
    or not line_obj.cells
    or line_obj.source_lnum ~= active.lnum
  then
    return chunks
  end

  local range = line_obj.cells[active.col]
  if not range then
    return chunks
  end

  return highlight_range(chunks, range.start_col, range.end_col)
end

local function padded_chunks(line_obj, line_index, target_width, active)
  local line = type(line_obj) == "table" and line_obj.text or line_obj
  local chunks = chunks_from_line_object(line_obj, line_index)
  chunks = apply_active_cell(chunks, line_obj, active)
  local missing = math.max(0, target_width - vim.api.nvim_strwidth(line))

  if missing > 0 then
    append_chunk(chunks, string.rep(" ", missing), "MarkdownTableWrapBlank")
  end

  return chunks
end

local function virt_lines(lines, start_index, active)
  local result = {}
  start_index = start_index or 1

  for index, line in ipairs(lines) do
    local chunks = chunks_from_line_object(line, start_index + index - 1)
    table.insert(result, apply_active_cell(chunks, line, active))
  end

  return result
end

function M.uses_conceal_lines(config)
  return (config or {}).inline_conceal_lines ~= false and (config or {}).inline_mode ~= "insert"
end

-- Where the rendered block hangs. `conceal_lines` marks give the table's source
-- lines zero height, and virt_lines attached to a hidden line are dropped, so
-- the block has to live on an ordinary line just outside the table: the one
-- above, or — for a table that starts at line 1 — the one below, drawn above
-- its own text. Returns nil when the conceal_lines renderer cannot be used and
-- the caller should fall back to the overlay renderer.
function M.block_anchor(bufnr, table_info, config)
  if not M.uses_conceal_lines(config) then
    return nil
  end

  bufnr = normalize_bufnr(bufnr)
  -- Always prefer hanging the block ABOVE the following line rather than below
  -- the preceding one. Both draw in the same place, but Neovim can only scroll
  -- into a virt_lines block through 'topfill', which counts filler drawn above
  -- the first buffer line shown: <C-e> walks an above-anchored block a row at a
  -- time, while a below-anchored one is skipped whole (measured: topline
  -- 18 -> 66 in a single 6-row scroll).
  local anchor, above
  if table_info.end_lnum < vim.api.nvim_buf_line_count(bufnr) then
    anchor, above = table_info.end_lnum + 1, true
  elseif table_info.start_lnum > 1 then
    anchor, above = table_info.start_lnum - 1, false
  else
    -- Table fills the buffer: nothing to hang the block off.
    return nil
  end

  -- Never anchor inside another table's hidden lines — the block would vanish.
  local marks = vim.api.nvim_buf_get_extmarks(bufnr, namespace, { anchor - 1, 0 }, { anchor - 1, -1 }, {
    details = true,
  })
  for _, mark in ipairs(marks) do
    if mark[4] and mark[4].conceal_lines then
      return nil
    end
  end

  return anchor, above
end

local function ensure_highlights(config)
  require("markdown-table-wrap.theme").apply(config)
end

local function set_render_window(winid, config)
  winid = winid or vim.api.nvim_get_current_win()
  if not vim.api.nvim_win_is_valid(winid) then
    return
  end

  local current = vim.wo[winid].conceallevel
  if current < 2 then
    if saved_conceallevels[winid] == nil then
      saved_conceallevels[winid] = current
    end
    vim.wo[winid].conceallevel = 2
  end

  if saved_concealcursors[winid] == nil then
    saved_concealcursors[winid] = vim.wo[winid].concealcursor
  end
  vim.wo[winid].concealcursor = "nvc"

  -- 'nowrap' is only needed by the overlay renderer: Neovim wraps a line by its
  -- raw character count regardless of conceal, so the 200-char source lines
  -- under a virt_text overlay each occupy several screen rows and tear the
  -- table apart. The conceal_lines renderer gives those lines zero height, so
  -- the window keeps whatever 'wrap' the user set (prose still soft-wraps).
  if config.inline_disable_wrap ~= false and not M.uses_conceal_lines(config) then
    if saved_wraps[winid] == nil then
      saved_wraps[winid] = vim.wo[winid].wrap
    end
    vim.wo[winid].wrap = false
  end
end

local function set_render_for_buffer(bufnr, config)
  for _, winid in ipairs(vim.fn.win_findbuf(bufnr)) do
    set_render_window(winid, config)
  end
end

local function restore_render_window(winid)
  local previous = saved_conceallevels[winid]
  if previous ~= nil and vim.api.nvim_win_is_valid(winid) then
    vim.wo[winid].conceallevel = previous
  end
  saved_conceallevels[winid] = nil

  local previous_cursor = saved_concealcursors[winid]
  if previous_cursor ~= nil and vim.api.nvim_win_is_valid(winid) then
    vim.wo[winid].concealcursor = previous_cursor
  end
  saved_concealcursors[winid] = nil

  local previous_wrap = saved_wraps[winid]
  if previous_wrap ~= nil and vim.api.nvim_win_is_valid(winid) then
    vim.wo[winid].wrap = previous_wrap
  end
  saved_wraps[winid] = nil
end

local function restore_render_for_buffer(bufnr)
  for _, winid in ipairs(vim.fn.win_findbuf(bufnr)) do
    restore_render_window(winid)
  end
end

local function conceal_source_line(bufnr, row)
  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
  if line == "" then
    return
  end

  vim.api.nvim_buf_set_extmark(bufnr, namespace, row, 0, {
    end_row = row,
    end_col = #line,
    conceal = "",
    priority = 9999,
  })
end

local function table_key(table_info)
  return tostring(table_info.start_lnum) .. ":" .. tostring(table_info.end_lnum)
end

local function view_offset(bufnr, table_info, source_count, rendered_count, config)
  if not config.inline_viewport_scrolling then
    return 0
  end

  view_offsets[bufnr] = view_offsets[bufnr] or {}
  local key = table_key(table_info)
  local max_offset = math.max(0, rendered_count - source_count)
  local offset = math.max(0, math.min(view_offsets[bufnr][key] or 0, max_offset))
  view_offsets[bufnr][key] = offset
  return offset
end

-- Hide the table's source lines outright (`conceal_lines`, zero screen rows)
-- and draw the whole rendered table as one virt_lines block on the anchor. The
-- window's 'wrap' is left alone, so prose around the table still soft-wraps.
local function show_conceal_lines(bufnr, table_info, config, rendered, active)
  local anchor, above = M.block_anchor(bufnr, table_info, config)
  if not anchor then
    return false
  end

  set_render_for_buffer(bufnr, config)
  local priority = config.overlay_priority or 10000

  for row = table_info.start_lnum - 1, table_info.end_lnum - 1 do
    vim.api.nvim_buf_set_extmark(bufnr, namespace, row, 0, {
      conceal_lines = "",
      priority = priority,
    })
  end

  vim.api.nvim_buf_set_extmark(bufnr, namespace, anchor - 1, 0, {
    virt_lines = virt_lines(rendered.line_objects or rendered.lines, 1, active),
    virt_lines_above = above,
    right_gravity = false,
    priority = priority,
  })

  return true
end

local function show_replace(bufnr, table_info, config, rendered, active)
  if show_conceal_lines(bufnr, table_info, config, rendered, active) then
    return
  end

  set_render_for_buffer(bufnr, config)

  local source_count = table_info.end_lnum - table_info.start_lnum + 1
  local rendered_count = #rendered.lines
  local first_rendered = view_offset(bufnr, table_info, source_count, rendered_count, config)
  local overlay_count = math.min(source_count, rendered_count - first_rendered)
  local start_row = table_info.start_lnum - 1
  local overlay_width = rendered.width
  if config.overlay_fill then
    -- Text area, not window width: the padding blanks exist to mask the raw
    -- source, and any column past the text area wraps onto a second screen row
    -- (a blank gap between every rendered table row) once 'wrap' is on.
    overlay_width = require("markdown-table-wrap.width").text_area(0)
  end
  local priority = config.overlay_priority or 10000

  for source_offset = 0, source_count - 1 do
    conceal_source_line(bufnr, start_row + source_offset)
  end

  for source_offset = 0, overlay_count - 1 do
    local line_obj = (rendered.line_objects or rendered.lines)[first_rendered + source_offset + 1]
    local mark = {
      virt_text = padded_chunks(line_obj, first_rendered + source_offset + 1, overlay_width, active),
      hl_mode = "replace",
      right_gravity = false,
      priority = priority,
    }

    if config.inline_virtual_text == "win_col" then
      mark.virt_text_win_col = 0
    else
      mark.virt_text_pos = "overlay"
    end

    vim.api.nvim_buf_set_extmark(bufnr, namespace, start_row + source_offset, 0, mark)
  end

  if rendered_count > overlay_count and not config.inline_viewport_scrolling then
    local extra = {}
    for index = overlay_count + 1, rendered_count do
      table.insert(extra, (rendered.line_objects or rendered.lines)[index])
    end

    vim.api.nvim_buf_set_extmark(bufnr, namespace, table_info.end_lnum - 1, 0, {
      virt_lines = virt_lines(extra, overlay_count + 1, active),
      virt_lines_above = false,
      right_gravity = false,
      priority = priority,
    })
  end
end

local function show_insert(bufnr, table_info, config, rendered, active)
  local target_line = math.max(table_info.start_lnum - 1, 0)
  local above = config.inline_position ~= "below"

  vim.api.nvim_buf_set_extmark(bufnr, namespace, target_line, 0, {
    virt_lines = virt_lines(rendered.line_objects or rendered.lines, 1, active),
    virt_lines_above = above,
    right_gravity = false,
    priority = 200,
  })

  if config.dim_source ~= false then
    for line = table_info.start_lnum - 1, table_info.end_lnum - 1 do
      vim.api.nvim_buf_set_extmark(bufnr, namespace, line, 0, {
        line_hl_group = "MarkdownTableWrapSource",
        priority = 100,
      })
    end
  end
end

function M.clear(bufnr)
  bufnr = normalize_bufnr(bufnr)

  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
  end

  active_buffers[bufnr] = nil
  active_tables[bufnr] = nil
  active_configs[bufnr] = nil
  active_cells[bufnr] = nil
  restore_render_for_buffer(bufnr)
end

function M.reset_view(bufnr)
  bufnr = normalize_bufnr(bufnr)
  view_offsets[bufnr] = nil
end

-- Tables currently rendered in this buffer, in document order.
function M.tables(bufnr)
  return active_tables[normalize_bufnr(bufnr)] or {}
end

function M.is_active(bufnr)
  bufnr = normalize_bufnr(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  local marks = vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, {})
  return #marks > 0
end

local function show_one(bufnr, table_info, config, active)
  local rendered = render.render_table(table_info, config)

  if config.inline_mode == "insert" then
    show_insert(bufnr, table_info, config, rendered, active)
  else
    show_replace(bufnr, table_info, config, rendered, active)
  end

  return rendered
end

function M.show(bufnr, table_info, config, active)
  ensure_highlights(config)
  M.clear(bufnr)

  local rendered = show_one(bufnr, table_info, config, active)
  active_buffers[bufnr] = true
  active_tables[bufnr] = { table_info }
  active_configs[bufnr] = config
  active_cells[bufnr] = active
  return rendered
end

function M.show_many(bufnr, tables, config, active)
  ensure_highlights(config)
  M.clear(bufnr)

  local rendered = {}
  for _, table_info in ipairs(tables) do
    table.insert(rendered, show_one(bufnr, table_info, config, active))
  end

  active_buffers[bufnr] = #tables > 0
  active_tables[bufnr] = tables
  active_configs[bufnr] = config
  active_cells[bufnr] = active
  return rendered
end

local function table_under_cursor(bufnr, tables)
  local cursor_lnum = vim.api.nvim_win_get_cursor(0)[1]
  for _, table_info in ipairs(tables) do
    if cursor_lnum >= table_info.start_lnum and cursor_lnum <= table_info.end_lnum then
      return table_info
    end
  end
  return nil
end

local function max_view_offset(table_info, config)
  local rendered = render.render_table(table_info, config)
  local source_count = table_info.end_lnum - table_info.start_lnum + 1
  return math.max(0, #rendered.lines - source_count)
end

function M.scroll(bufnr, delta)
  bufnr = normalize_bufnr(bufnr)
  local tables = active_tables[bufnr]
  local config = active_configs[bufnr]
  if not tables or not config or not config.inline_viewport_scrolling then
    return false
  end

  local target = table_under_cursor(bufnr, tables)
  if not target then
    return false
  end

  local max_offset = max_view_offset(target, config)
  if max_offset == 0 then
    return false
  end

  view_offsets[bufnr] = view_offsets[bufnr] or {}
  local key = table_key(target)
  local current = view_offsets[bufnr][key] or 0
  local next_offset = math.max(0, math.min(current + delta, max_offset))
  if next_offset == current then
    return true
  end

  view_offsets[bufnr][key] = next_offset
  M.show_many(bufnr, tables, config, active_cells[bufnr])
  return true
end

function M.scroll_to(bufnr, position)
  bufnr = normalize_bufnr(bufnr)
  local tables = active_tables[bufnr]
  local config = active_configs[bufnr]
  if not tables or not config or not config.inline_viewport_scrolling then
    return false
  end

  local target = table_under_cursor(bufnr, tables)
  if not target then
    return false
  end

  local max_offset = max_view_offset(target, config)
  view_offsets[bufnr] = view_offsets[bufnr] or {}
  view_offsets[bufnr][table_key(target)] = position == "bottom" and max_offset or 0
  M.show_many(bufnr, tables, config, active_cells[bufnr])
  return true
end

function M.attach_window(bufnr)
  bufnr = normalize_bufnr(bufnr)
  if active_buffers[bufnr] then
    set_render_for_buffer(bufnr, active_configs[bufnr] or {})
  end
end

function M.namespace()
  return namespace
end

return M
