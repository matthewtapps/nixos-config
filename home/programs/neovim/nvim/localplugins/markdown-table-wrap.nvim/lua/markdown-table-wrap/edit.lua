local M = {}

-- Escaped pipes (\|) mark cell-internal pipes in the source; show them bare in
-- the editor and re-escape on save. Pipes inside backtick code spans are left
-- untouched in both directions to match the parser's pipe handling.
local function unescape_pipes(text)
  return (text:gsub("\\|", "|"))
end

M.unescape_pipes = unescape_pipes

local function escape_pipes(text)
  local out = {}
  local in_code = false
  local index = 1

  while index <= #text do
    local ch = text:sub(index, index)
    if ch == "`" then
      in_code = not in_code
      table.insert(out, ch)
    elseif ch == "\\" then
      table.insert(out, text:sub(index, index + 1))
      index = index + 1
    elseif ch == "|" and not in_code then
      table.insert(out, "\\|")
    else
      table.insert(out, ch)
    end
    index = index + 1
  end

  return table.concat(out)
end

M.escape_pipes = escape_pipes

-- Background API edits with no sync point in between merge into one undo
-- block; force a break so each discrete cell operation undoes on its own.
function M.undo_break(bufnr)
  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd("let &undolevels = &undolevels")
  end)
end

local function header_label(bufnr, lnum, cell_index)
  local parser = require("markdown-table-wrap.parser")
  local ok, info = pcall(parser.parse_at_cursor, bufnr, lnum)
  if not ok or not info then
    return nil
  end

  local cell = info.header[cell_index]
  local text = type(cell) == "table" and cell.text or cell
  text = vim.trim(tostring(text or ""))
  return text ~= "" and text or nil
end

--- Open a floating editor for one table cell.
---
--- opts (all optional; defaults target the cell under the cursor):
---   source_buf, lnum, cell_index — which cell to edit
---   position — nvim_open_win config fragment for exact placement (in-place
---     editing over the rendered cell); when absent a cursor-anchored modal
---     with a border is used
---   live — write changes through to the source on every edit (default true
---     when position is given, false otherwise)
---   offset — byte offset into the cell text to place the editor cursor at
---   insert — enter insert mode: "at_offset" | "after_offset" | "start" |
---     "append". Leaving insert mode then saves and closes the editor, so an
---     i-edit-Esc round trip lands back where it started.
---   truncate — cut the cell text at offset before editing (C semantics)
---   on_close(saved) — called after the editor window closes
function M.edit_cell(opts)
  opts = opts or {}
  local nav = require("markdown-table-wrap.nav")
  local source_buf = opts.source_buf or vim.api.nvim_get_current_buf()

  local lnum, cell_index = opts.lnum, opts.cell_index
  if not lnum or not cell_index then
    local cursor = vim.api.nvim_win_get_cursor(0)
    lnum = cursor[1]
    local cursor_line = vim.api.nvim_buf_get_lines(source_buf, lnum - 1, lnum, false)[1] or ""
    cell_index = (nav.cell_index_at(cursor_line, cursor[2]))
  end

  local line = vim.api.nvim_buf_get_lines(source_buf, lnum - 1, lnum, false)[1] or ""
  local spans = nav.spans(line)
  local span = cell_index and spans[cell_index]

  if not span then
    vim.notify("MarkdownTableWrap: cursor is not inside a table cell.", vim.log.levels.INFO)
    return
  end

  local original_raw = line:sub(span.start_col + 1, span.end_col)
  local text = unescape_pipes(vim.trim(original_raw))
  local offset = math.max(0, math.min(opts.offset or 0, #text))
  if opts.truncate then
    text = text:sub(1, offset)
  elseif opts.delete_range then
    -- Change-operator entry: the covered region is removed and insert starts
    -- at its left edge.
    local from = math.max(0, math.min(opts.delete_range[1], #text))
    local to = math.max(from, math.min(opts.delete_range[2], #text))
    text = text:sub(1, from) .. text:sub(to + 1)
    offset = from
  end
  local header = header_label(source_buf, lnum, cell_index)
  local live = opts.live
  if live == nil then
    live = opts.position ~= nil
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text })
  vim.api.nvim_buf_set_name(buf, ("mtw-cell://%d/%d/%d"):format(source_buf, lnum, cell_index))
  vim.bo[buf].buftype = "acwrite"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "markdown"
  -- A truncate (C) or region delete (cw/ciw/…) is already an edit even
  -- before the user types.
  vim.bo[buf].modified = opts.truncate == true or opts.delete_range ~= nil

  local win_config
  if opts.position then
    win_config = vim.tbl_extend("force", {
      style = "minimal",
      border = "none",
      zindex = 80,
    }, opts.position)
  else
    local width = math.min(60, math.max(30, vim.o.columns - 10))
    win_config = {
      relative = "cursor",
      row = 1,
      col = 0,
      width = width,
      height = math.max(3, math.min(12, math.ceil(vim.api.nvim_strwidth(text) / width) + 1)),
      style = "minimal",
      border = "rounded",
      title = (" Edit cell%s "):format(header and (" · " .. header) or ""),
      title_pos = "center",
      footer = " <Esc>/q save · <C-c> discard ",
      footer_pos = "center",
    }
  end

  local win = vim.api.nvim_open_win(buf, true, win_config)
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  if opts.position then
    -- Blend into the rendered table; tint so the live-edit region is visible.
    vim.wo[win].winhighlight = "Normal:MarkdownTableWrapActiveCell,NormalFloat:MarkdownTableWrapActiveCell"
  end

  local closed = false
  local saved_any = false
  local wrote_before = false

  local function write_source(new_text)
    -- Re-locate the cell each time: live writes change the line's length.
    local current = vim.api.nvim_buf_get_lines(source_buf, lnum - 1, lnum, false)[1] or ""
    local current_spans = nav.spans(current)
    local target = current_spans[cell_index]
    if not target then
      return false
    end
    vim.api.nvim_buf_call(source_buf, function()
      -- Collapse the whole editing session into one undo step so `u` in the
      -- document undoes the cell edit atomically, not keystroke chunks — but
      -- break from whatever change preceded the session.
      if wrote_before then
        pcall(vim.cmd, "silent! undojoin")
      else
        vim.cmd("let &undolevels = &undolevels")
      end
      vim.api.nvim_buf_set_text(source_buf, lnum - 1, target.start_col, lnum - 1, target.end_col, { new_text })
    end)
    wrote_before = true
    return true
  end

  local function save()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local joined = escape_pipes(vim.trim(table.concat(lines, " ")))
    if not write_source(joined) then
      vim.notify("MarkdownTableWrap: table changed underneath; cell not written.", vim.log.levels.WARN)
      return false
    end
    saved_any = true
    vim.bo[buf].modified = false
    return true
  end

  local function close(saved)
    if closed then
      return
    end
    closed = true
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    -- on_close runs synchronously: it restores focus, and deferring it races
    -- against whatever the user does next (e.g. immediately opening another
    -- cell editor, which the deferred focus restore would then steal from).
    if opts.on_close then
      opts.on_close(saved)
    end
    vim.schedule(function()
      -- Background edits don't fire TextChanged in the source buffer, so
      -- refresh the overlay explicitly.
      require("markdown-table-wrap").refresh_auto({ force = true, silent = true })
    end)
  end

  local function discard()
    if saved_any or vim.bo[buf].modified then
      write_source(original_raw)
    end
    vim.bo[buf].modified = false
    close(false)
  end

  if live then
    local pending = false
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
      buffer = buf,
      callback = function()
        if pending or closed then
          return
        end
        pending = true
        vim.defer_fn(function()
          pending = false
          if not closed and vim.api.nvim_buf_is_valid(buf) then
            save()
            if opts.on_live_update then
              opts.on_live_update()
            end
          end
        end, 120)
      end,
    })
  end

  -- :w saves the cell and writes the whole document, so the editor behaves
  -- like editing ordinary buffer text.
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      if save() and vim.api.nvim_buf_is_valid(source_buf) then
        vim.api.nvim_buf_call(source_buf, function()
          vim.cmd("silent write")
        end)
      end
    end,
  })

  local function save_and_close()
    if not vim.bo[buf].modified or save() then
      close(true)
    end
  end

  vim.keymap.set("n", "q", save_and_close, { buffer = buf, nowait = true, silent = true, desc = "Save cell and close" })
  vim.keymap.set("n", "<Esc>", save_and_close, { buffer = buf, nowait = true, silent = true, desc = "Save cell and close" })
  vim.keymap.set("n", "<C-c>", discard, { buffer = buf, nowait = true, silent = true, desc = "Discard cell edit" })

  -- Cursor placement / insert-mode entry per opts.
  local function char_len_at(str, byte_offset)
    local ch = str:sub(byte_offset + 1):match("^[%z\1-\127\194-\244][\128-\191]*")
    return ch and #ch or 1
  end

  local current_text = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
  local target_col = offset
  if opts.insert == "start" then
    target_col = 0
  elseif opts.insert == "append" or opts.truncate then
    target_col = #current_text
  elseif opts.insert == "after_offset" then
    target_col = math.min(offset + char_len_at(current_text, offset), #current_text)
  end
  pcall(vim.api.nvim_win_set_cursor, win, { 1, math.min(target_col, math.max(0, #current_text - 1)) })

  if opts.insert then
    if target_col >= #current_text then
      vim.cmd("startinsert!")
    else
      vim.cmd("startinsert")
    end

    -- i-edit-Esc round trip: leaving insert mode saves and closes, dropping
    -- the user back where the edit started (e.g. table focus mode).
    vim.api.nvim_create_autocmd("InsertLeave", {
      buffer = buf,
      once = true,
      callback = function()
        if not closed then
          save_and_close()
        end
      end,
    })
  end

  return win, buf
end

return M
