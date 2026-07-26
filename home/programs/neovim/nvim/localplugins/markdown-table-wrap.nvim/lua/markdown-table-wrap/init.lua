local M = {}

M.version = "0.1.4"

local defaults = {
  max_width_ratio = 0.9,
  min_col_width = 8,
  max_col_width = 50,
  border = "rounded",
  use_unicode_border = true,
  table_border = "rounded",
  row_separator = true,
  preview_mode = "inline",
  inline_mode = "replace",
  inline_position = "above",
  dim_source = true,
  auto_preview = true,
  auto_focus = false,
  render_all = true,
  auto_preview_in_insert = false,
  clear_on_cursor_leave = true,
  clear_on_insert = true,
  clear_on_visual = true,
  debounce_ms = 80,
  overlay_priority = 10000,
  overlay_fill = true,
  inline_virtual_text = "overlay",
  -- Hide table source lines with `conceal_lines` (zero screen rows) and draw
  -- the table as one virt_lines block, instead of overlaying virt_text on the
  -- concealed-but-still-full-height source lines. Set false for the legacy
  -- overlay renderer, which needs 'nowrap' to look right.
  inline_conceal_lines = true,
  inline_disable_wrap = true,
  inline_viewport_scrolling = false,
  highlight_preset = "default",
  theme_dir = nil,
  themes = {},
  highlights = {},
  map_gx = true,
  link = {
    icon = "",
    wiki = { icon = " ", highlight = "MarkdownTableWrapWikiLink", scope_highlight = "MarkdownTableWrapWikiLink" },
    image = " ",
    custom = {
      github = { pattern = "github", icon = " " },
      gitlab = { pattern = "gitlab", icon = "󰮠 " },
      youtube = { pattern = "youtube", icon = " " },
      bilibili = { pattern = "bilibili", icon = "󰟴 " },
      cern = { pattern = "cern.ch", icon = " " },
    },
  },
}

M.config = vim.deepcopy(defaults)
M.state = {
  win = nil,
  buf = nil,
  inline_buf = nil,
  augroup = nil,
  refresh_token = 0,
  paused_buffers = {},
  last_signature = {},
  did_setup = false,
  visual_buffers = {},
  active_cell = {},
}

local function is_markdown_buffer()
  local ft = vim.bo.filetype
  return ft == "markdown" or ft == "md" or ft == "quarto" or ft == "rmarkdown"
end

local function validate_config()
  M.config.max_width_ratio = tonumber(M.config.max_width_ratio) or defaults.max_width_ratio
  M.config.min_col_width = math.max(1, tonumber(M.config.min_col_width) or defaults.min_col_width)
  M.config.max_col_width = math.max(M.config.min_col_width, tonumber(M.config.max_col_width) or defaults.max_col_width)
  M.config.debounce_ms = math.max(0, tonumber(M.config.debounce_ms) or defaults.debounce_ms)
  M.config.overlay_priority = math.max(1, tonumber(M.config.overlay_priority) or defaults.overlay_priority)
  M.config.render_all = M.config.render_all ~= false
  M.config.auto_focus = M.config.auto_focus == true
  M.config.overlay_fill = M.config.overlay_fill ~= false
  M.config.clear_on_visual = M.config.clear_on_visual ~= false
  M.config.inline_conceal_lines = M.config.inline_conceal_lines ~= false
  M.config.inline_disable_wrap = M.config.inline_disable_wrap ~= false
  M.config.inline_viewport_scrolling = M.config.inline_viewport_scrolling ~= false
  M.config.map_gx = M.config.map_gx ~= false

  if M.config.inline_virtual_text ~= "overlay" and M.config.inline_virtual_text ~= "win_col" then
    M.config.inline_virtual_text = defaults.inline_virtual_text
  end

  if M.config.preview_mode ~= "inline" and M.config.preview_mode ~= "float" then
    M.config.preview_mode = defaults.preview_mode
  end

  if M.config.inline_mode ~= "replace" and M.config.inline_mode ~= "insert" then
    M.config.inline_mode = defaults.inline_mode
  end

  if M.config.inline_position ~= "above" and M.config.inline_position ~= "below" then
    M.config.inline_position = defaults.inline_position
  end

  if M.config.table_border ~= "rounded" and M.config.table_border ~= "single" then
    M.config.table_border = defaults.table_border
  end

  local valid_presets = {}
  for _, preset in ipairs(require("markdown-table-wrap.theme").presets()) do
    valid_presets[preset] = true
  end
  if not valid_presets[M.config.highlight_preset] then
    M.config.highlight_preset = defaults.highlight_preset
  end
end

local function close_existing()
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    vim.api.nvim_win_close(M.state.win, true)
  end

  if M.state.buf and vim.api.nvim_buf_is_valid(M.state.buf) then
    vim.api.nvim_buf_delete(M.state.buf, { force = true })
  end

  M.state.win = nil
  M.state.buf = nil
end

local function active_cell_key(bufnr)
  local active = M.state.active_cell[bufnr]
  if not active then
    return "none"
  end
  return tostring(active.lnum) .. ":" .. tostring(active.col)
end

-- The active cell is derived from the raw cursor position, without parsing the
-- whole table; the renderer only highlights it when the line actually belongs
-- to a rendered table, so false positives are harmless.
local function update_active_cell(bufnr)
  local nav = require("markdown-table-wrap.nav")
  local lnum, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
  local active = nil

  if line:find("|", 1, true) then
    local index = (nav.cell_index_at(line, col))
    if index then
      active = { lnum = lnum, col = index }
    end
  end

  local previous = M.state.active_cell[bufnr]
  local changed = (previous and previous.lnum) ~= (active and active.lnum)
    or (previous and previous.col) ~= (active and active.col)
  M.state.active_cell[bufnr] = active
  return changed
end

local function table_signature(bufnr, table_info)
  local lines = vim.api.nvim_buf_get_lines(bufnr, table_info.start_lnum - 1, table_info.end_lnum, false)
  return table.concat({
    active_cell_key(bufnr),
    tostring(table_info.start_lnum),
    tostring(table_info.end_lnum),
    tostring(vim.api.nvim_win_get_width(0)),
    tostring(M.config.max_width_ratio),
    tostring(M.config.min_col_width),
    tostring(M.config.max_col_width),
    M.config.use_unicode_border and "unicode" or "ascii",
    tostring(M.config.table_border),
    tostring(M.config.row_separator),
    tostring(M.config.inline_mode),
    tostring(M.config.clear_on_visual),
    tostring(M.config.inline_virtual_text),
    tostring(M.config.inline_disable_wrap),
    tostring(M.config.inline_viewport_scrolling),
    table.concat(lines, "\n"),
  }, "\31")
end

local function all_tables_signature(bufnr, tables)
  local parts = {
    active_cell_key(bufnr),
    tostring(vim.api.nvim_buf_get_changedtick(bufnr)),
    tostring(vim.api.nvim_win_get_width(0)),
    tostring(M.config.max_width_ratio),
    tostring(M.config.min_col_width),
    tostring(M.config.max_col_width),
    M.config.use_unicode_border and "unicode" or "ascii",
    tostring(M.config.table_border),
    tostring(M.config.row_separator),
    tostring(M.config.inline_mode),
    tostring(M.config.clear_on_visual),
    tostring(M.config.inline_virtual_text),
    tostring(M.config.inline_disable_wrap),
    tostring(M.config.overlay_fill),
    tostring(M.config.inline_viewport_scrolling),
  }

  for _, table_info in ipairs(tables) do
    table.insert(parts, tostring(table_info.start_lnum))
    table.insert(parts, tostring(table_info.end_lnum))
  end

  return table.concat(parts, "\31")
end

function M.close_preview()
  close_existing()
  local bufnr = M.state.inline_buf or vim.api.nvim_get_current_buf()
  require("markdown-table-wrap.inline").clear(bufnr)
  M.state.inline_buf = nil
  M.state.paused_buffers[bufnr] = true
end

local function table_under_cursor(opts)
  opts = opts or {}

  if not is_markdown_buffer() then
    if not opts.silent then
      vim.notify("MarkdownTableWrap: preview is only available in Markdown buffers.", vim.log.levels.INFO)
    end
    return nil
  end

  local parser = require("markdown-table-wrap.parser")
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local table_info, err = parser.parse_at_cursor(bufnr, cursor[1])

  if not table_info then
    if not opts.silent then
      vim.notify(err or "MarkdownTableWrap: cursor is not inside a Markdown pipe table.", vim.log.levels.INFO)
    end
    return nil
  end

  return bufnr, table_info
end

function M.inline_preview()
  local bufnr, table_info = table_under_cursor()
  if not bufnr then
    return
  end

  close_existing()
  M.state.paused_buffers[bufnr] = nil
  require("markdown-table-wrap.inline").show(bufnr, table_info, M.config)
  M.state.last_signature[bufnr] = table_signature(bufnr, table_info)
  M.state.inline_buf = bufnr
end

function M.float_preview()
  local bufnr, table_info = table_under_cursor()
  if not bufnr then
    return
  end

  close_existing()

  local render = require("markdown-table-wrap.render")
  local rendered = render.render_table(table_info, M.config)
  local buf, win = render.open_float(rendered, M.config)
  M.state.buf = buf
  M.state.win = win
end

function M.preview()
  if M.config.preview_mode == "float" then
    M.float_preview()
    return
  end

  M.inline_preview()
end

function M.refresh_auto(opts)
  opts = opts or {}
  local bufnr = vim.api.nvim_get_current_buf()
  local inline = require("markdown-table-wrap.inline")

  if not M.config.auto_preview and not opts.force then
    return
  end

  if M.state.paused_buffers[bufnr] and not opts.force then
    return
  end

  if not is_markdown_buffer() then
    inline.clear(bufnr)
    return
  end

  local mode = vim.api.nvim_get_mode().mode
  if not M.config.auto_preview_in_insert and mode:match("^i") then
    inline.clear(bufnr)
    M.state.inline_buf = nil
    M.state.last_signature[bufnr] = nil
    return
  end

  local parser = require("markdown-table-wrap.parser")
  if M.config.render_all then
    local tables = parser.parse_all(bufnr)
    if #tables == 0 then
      inline.clear(bufnr)
      M.state.inline_buf = nil
      M.state.last_signature[bufnr] = nil
      return
    end

    local signature = all_tables_signature(bufnr, tables)
    if not opts.force and M.state.last_signature[bufnr] == signature and inline.is_active(bufnr) then
      inline.attach_window(bufnr)
      return
    end

    close_existing()
    inline.show_many(bufnr, tables, M.config, M.state.active_cell[bufnr])
    M.state.last_signature[bufnr] = signature
    M.state.inline_buf = bufnr
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local table_info = parser.parse_at_cursor(bufnr, cursor[1])

  if not table_info then
    if M.config.clear_on_cursor_leave ~= false then
      inline.clear(bufnr)
      if M.state.inline_buf == bufnr then
        M.state.inline_buf = nil
      end
      M.state.last_signature[bufnr] = nil
    end
    return
  end

  local signature = table_signature(bufnr, table_info)
  if not opts.force and M.state.last_signature[bufnr] == signature and inline.is_active(bufnr) then
    inline.attach_window(bufnr)
    return
  end

  close_existing()
  inline.show(bufnr, table_info, M.config, M.state.active_cell[bufnr])
  M.state.last_signature[bufnr] = signature
  M.state.inline_buf = bufnr
end

function M.schedule_refresh(opts)
  opts = opts or {}
  M.state.refresh_token = M.state.refresh_token + 1
  local token = M.state.refresh_token
  local delay = opts.immediate and 0 or M.config.debounce_ms

  vim.defer_fn(function()
    if token ~= M.state.refresh_token then
      return
    end

    if vim.api.nvim_get_current_buf() == 0 then
      return
    end

    M.refresh_auto(opts)
  end, delay)
end

function M.toggle_preview()
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    close_existing()
    return
  end

  local inline = require("markdown-table-wrap.inline")
  local bufnr = vim.api.nvim_get_current_buf()
  if inline.is_active(bufnr) then
    inline.clear(bufnr)
    M.state.inline_buf = nil
    M.state.last_signature[bufnr] = nil
    M.state.paused_buffers[bufnr] = true
    return
  end

  M.preview()
end

function M.enable_auto_preview()
  local bufnr = vim.api.nvim_get_current_buf()
  M.state.paused_buffers[bufnr] = nil
  M.config.auto_preview = true
  M.refresh_auto({ force = true })
end

function M.disable_auto_preview()
  local bufnr = vim.api.nvim_get_current_buf()
  M.state.paused_buffers[bufnr] = true
  require("markdown-table-wrap.inline").clear(bufnr)
  if M.state.inline_buf == bufnr then
    M.state.inline_buf = nil
  end
  M.state.last_signature[bufnr] = nil
end

function M.toggle_auto_preview()
  local bufnr = vim.api.nvim_get_current_buf()
  if M.state.paused_buffers[bufnr] then
    M.enable_auto_preview()
  else
    M.disable_auto_preview()
  end
end

function M.toggle_inline_viewport_scrolling()
  M.config.inline_viewport_scrolling = not M.config.inline_viewport_scrolling
  local bufnr = vim.api.nvim_get_current_buf()
  require("markdown-table-wrap.inline").reset_view(bufnr)
  M.state.last_signature[bufnr] = nil
  M.refresh_auto({ force = true })
  vim.notify(
    string.format(
      "MarkdownTableWrap: inline viewport scrolling %s",
      M.config.inline_viewport_scrolling and "enabled" or "disabled"
    ),
    vim.log.levels.INFO
  )
end

function M.scroll_view(delta)
  if require("markdown-table-wrap.inline").scroll(vim.api.nvim_get_current_buf(), delta) then
    return
  end

  local keys = delta > 0 and [[\<C-E>]] or [[\<C-Y>]]
  vim.cmd("normal! " .. tostring(math.max(1, math.abs(delta))) .. keys)
end

function M.scroll_view_to(position)
  if require("markdown-table-wrap.inline").scroll_to(vim.api.nvim_get_current_buf(), position) then
    return
  end

  if position == "bottom" then
    vim.cmd("normal! G")
  else
    vim.cmd("normal! gg")
  end
end

-- Seed a minimal one-column, one-row table below the cursor line and land on
-- it (auto_focus then enters it for editing).
function M.create_table()
  local bufnr = vim.api.nvim_get_current_buf()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local current = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
  local rows = { "| Column |", "|---|", "|   |" }
  if current ~= "" then
    table.insert(rows, 1, "")
  end

  require("markdown-table-wrap.edit").undo_break(bufnr)
  vim.api.nvim_buf_set_lines(bufnr, lnum, lnum, false, rows)
  vim.api.nvim_win_set_cursor(0, { lnum + #rows, 0 })
  M.schedule_refresh({ silent = true, immediate = true })
end

-- Run `apply` — something that adds or removes rendered tables — and put the
-- cursor back on the screen row it was on.
--
-- A rendered table is many screen rows taller than its source, so dropping the
-- rendering for insert mode collapses the document under the cursor (and
-- restoring it expands it again). Neovim then re-derives the view from the
-- buffer alone and the cursor can land anywhere. Everything around it is free
-- to move; the line being edited staying put is what makes that legible.
local function keeping_cursor_row(bufnr, apply)
  local win = vim.api.nvim_get_current_win()
  local viewport = require("markdown-table-wrap.viewport")
  local ok, row = pcall(vim.api.nvim_win_call, win, vim.fn.winline)

  apply()

  if not ok or not vim.api.nvim_win_is_valid(win) then
    return
  end
  if vim.api.nvim_win_get_buf(win) ~= bufnr then
    return
  end
  local lnum = vim.api.nvim_win_get_cursor(win)[1]
  local margin, win_h = viewport.margin(win)
  pcall(viewport.place, win, bufnr, lnum, row, { margin, win_h - margin - 1 })
  viewport.set_last(win, bufnr, lnum, vim.api.nvim_win_call(win, vim.fn.winline))
end

local function create_autocmds()
  if M.state.augroup then
    vim.api.nvim_del_augroup_by_id(M.state.augroup)
  end

  M.state.augroup = vim.api.nvim_create_augroup("MarkdownTableWrap", { clear = true })

  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = M.state.augroup,
    callback = function(args)
      if not is_markdown_buffer() then
        return
      end

      local changed = update_active_cell(args.buf)

      -- Before anything else: Neovim has already settled the view for this
      -- motion, and across a rendered table it settles it wrong (the block is
      -- atomic to its scroll code). Put the cursor back on the screen row the
      -- motion actually earned, so focus mode and the document agree.
      if M.config.auto_focus and not require("markdown-table-wrap.view").is_open() then
        require("markdown-table-wrap.viewport").follow(vim.api.nvim_get_current_win(), args.buf)
      end

      if M.config.auto_focus then
        require("markdown-table-wrap.view").try_auto_enter()
      end

      if M.config.render_all then
        if changed then
          M.schedule_refresh({ silent = true })
        end
        return
      end

      M.schedule_refresh({ silent = true })
    end,
  })

  vim.api.nvim_create_autocmd(
    { "TextChanged", "TextChangedI", "InsertLeave", "BufWinEnter", "WinScrolled", "VimResized" },
    {
      group = M.state.augroup,
      callback = function(args)
        if not is_markdown_buffer() then
          return
        end
        -- A view change with the cursor still on the same line is the user's
        -- own (zz, <C-e>, a resize). Adopt it as the new baseline rather than
        -- correcting the next motion back towards a stale row.
        if args.event == "WinScrolled" or args.event == "VimResized" then
          require("markdown-table-wrap.viewport").note(vim.api.nvim_get_current_win())
        end
        M.schedule_refresh({ silent = true })
      end,
    }
  )

  vim.api.nvim_create_autocmd("InsertEnter", {
    group = M.state.augroup,
    callback = function()
      if M.config.auto_preview_in_insert or not M.config.clear_on_insert then
        return
      end

      local bufnr = vim.api.nvim_get_current_buf()
      keeping_cursor_row(bufnr, function()
        require("markdown-table-wrap.inline").clear(bufnr)
        if M.state.inline_buf == bufnr then
          M.state.inline_buf = nil
        end
        M.state.last_signature[bufnr] = nil
      end)
    end,
  })

  vim.api.nvim_create_autocmd("InsertLeave", {
    group = M.state.augroup,
    callback = function()
      if M.config.auto_preview_in_insert or not M.config.clear_on_insert then
        return
      end
      if not is_markdown_buffer() then
        return
      end

      -- Re-render inside the same guard, so the document expanding back to its
      -- rendered height is as undisruptive as the collapse was. Done eagerly
      -- rather than through the debounce: the row can only be restored once the
      -- tables are actually back.
      local bufnr = vim.api.nvim_get_current_buf()
      keeping_cursor_row(bufnr, function()
        M.refresh_auto({ force = true, silent = true })
      end)
    end,
  })

  vim.api.nvim_create_autocmd("ModeChanged", {
    group = M.state.augroup,
    callback = function()
      if not is_markdown_buffer() or M.config.clear_on_visual == false then
        return
      end

      local bufnr = vim.api.nvim_get_current_buf()
      local mode = vim.api.nvim_get_mode().mode
      local visual = mode:match("^[vV\22]") ~= nil

      if visual then
        require("markdown-table-wrap.inline").clear(bufnr)
        if M.state.inline_buf == bufnr then
          M.state.inline_buf = nil
        end
        M.state.last_signature[bufnr] = nil
        M.state.visual_buffers[bufnr] = true
      elseif M.state.visual_buffers[bufnr] then
        M.state.visual_buffers[bufnr] = nil
        M.schedule_refresh({ silent = true })
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
    group = M.state.augroup,
    callback = function(args)
      require("markdown-table-wrap.inline").attach_window(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
    group = M.state.augroup,
    callback = function(args)
      if M.config.render_all then
        return
      end

      if M.config.clear_on_cursor_leave ~= false then
        require("markdown-table-wrap.inline").clear(args.buf)
        if M.state.inline_buf == args.buf then
          M.state.inline_buf = nil
        end
        M.state.last_signature[args.buf] = nil
      end
    end,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    group = M.state.augroup,
    callback = function(args)
      -- Window ids get reused; a remembered cursor row from the previous
      -- occupant would be applied to the next one's first motion.
      require("markdown-table-wrap.viewport").forget(tonumber(args.match))
    end,
  })

  vim.api.nvim_create_autocmd("BufWipeout", {
    group = M.state.augroup,
    callback = function(args)
      M.state.paused_buffers[args.buf] = nil
      M.state.last_signature[args.buf] = nil
      M.state.visual_buffers[args.buf] = nil
      M.state.active_cell[args.buf] = nil
      if M.state.inline_buf == args.buf then
        M.state.inline_buf = nil
      end
    end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    group = M.state.augroup,
    pattern = { "markdown", "md", "quarto", "rmarkdown" },
    callback = function(args)
      if M.config.auto_focus then
        for lhs, direction in pairs({ ["<C-d>"] = 1, ["<C-u>"] = -1 }) do
          vim.keymap.set("n", lhs, function()
            local count = vim.v.count > 0 and vim.v.count or nil
            if M.scroll_screen(direction, count) then
              return
            end
            -- Nothing rendered in the way: plain native scroll. No count
            -- prefix unless the user typed one — {count}<C-u> permanently SETS
            -- the window's 'scroll' option.
            local prefix = count and tostring(count) or ""
            vim.cmd("normal! " .. prefix .. vim.api.nvim_replace_termcodes(lhs, true, false, true))
          end, { buffer = args.buf, silent = true, desc = "Scroll half page (table-aware)" })
        end
      end

      if not M.config.map_gx then
        return
      end

      vim.keymap.set("n", "gx", function()
        if not require("markdown-table-wrap.nav").open_link() then
          local parser = require("markdown-table-wrap.parser")
          local table_info = parser.parse_at_cursor(vim.api.nvim_get_current_buf(), vim.api.nvim_win_get_cursor(0)[1])
          if table_info then
            return
          end
          vim.cmd("normal! gx")
        end
      end, { buffer = args.buf, silent = true, desc = "Open Markdown table link" })
    end,
  })
end

-- Screen rows a single line occupies, excluding any virt_lines hanging off it
-- (`fill`) — those belong to a table block and are counted separately.
local function line_text_rows(win, lnum)
  local ok, height = pcall(vim.api.nvim_win_text_height, win, { start_row = lnum - 1, end_row = lnum - 1 })
  if not ok then
    return 1
  end
  return math.max(0, height.all - height.fill)
end

-- Table-aware half-page scrolling.
--
-- A rendered table occupies far more screen rows than source lines (42 source
-- lines can render to 163 rows), and Neovim cannot walk a virt_lines block
-- taller than the window: 'topfill' is capped at the window height, so <C-e>
-- either steps through the block's tail or skips the whole thing. A plain
-- <C-d>/<C-u> next to a big table therefore overshoots it or stalls against it.
--
-- So measure the motion in SCREEN ROWS, counting each table as its rendered
-- height, and when the landing point falls inside a table open focus mode at
-- exactly that rendered row — a half page down lands half a page into the
-- table, and the next press continues from there (focus mode's own <C-d>/<C-u>
-- take over, spilling back out at the far edge).
--
-- Returns true when the motion was handled here, false to fall back to native
-- scrolling.
function M.scroll_screen(direction, count)
  local inline = require("markdown-table-wrap.inline")
  local view = require("markdown-table-wrap.view")
  local win = vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_get_current_buf()

  local tables = inline.tables(bufnr)
  if #tables == 0 then
    return false
  end

  local win_h = vim.api.nvim_win_get_height(win)
  local scroll = vim.api.nvim_get_option_value("scroll", { win = win, scope = "local" })
  local remaining = count or (scroll > 0 and scroll or math.max(1, math.floor(win_h / 2)))
  local last = vim.api.nvim_buf_line_count(bufnr)
  local start_lnum = vim.api.nvim_win_get_cursor(win)[1]
  local lnum = start_lnum
  -- Native <C-d>/<C-u> move the view and the cursor by the same amount, so the
  -- cursor keeps its screen row. Remember it and land on it.
  local start_row = vim.api.nvim_win_call(win, vim.fn.winline)

  while remaining > 0 do
    local next_lnum = lnum + direction
    if next_lnum < 1 or next_lnum > last then
      break
    end

    local hit
    for _, table_info in ipairs(tables) do
      if next_lnum >= table_info.start_lnum and next_lnum <= table_info.end_lnum then
        hit = table_info
        break
      end
    end

    if hit then
      local height = view.rendered_height(hit, win)
      if remaining <= height then
        -- Counting down: `remaining` rows into the top. Counting up: the same
        -- distance measured from the bottom.
        view.enter_at(hit, direction > 0 and remaining or (height - remaining + 1), start_row)
        return true
      end
      remaining = remaining - height
      lnum = direction > 0 and hit.end_lnum or hit.start_lnum
    else
      remaining = remaining - math.max(1, line_text_rows(win, next_lnum))
      lnum = next_lnum
    end
  end

  -- Nothing moved (buffer edge): let the native key have it.
  if lnum == start_lnum then
    return false
  end

  -- Take the motion even when no table was crossed. Native <C-d>/<C-u> move by
  -- SCREEN rows and then keep the cursor at its old screen row, which lands it
  -- inside the zero-height source lines of a table further down the buffer —
  -- auto-focus then opens that table at an arbitrary row. Placing the cursor
  -- ourselves keeps the motion exactly as far as it was measured, and placing
  -- the view with it keeps the cursor on the screen row it started from.
  require("markdown-table-wrap.viewport").jump(win, bufnr, math.max(1, math.min(last, lnum)), start_row)
  return true
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
  validate_config()
  create_autocmds()
  M.state.did_setup = true

  vim.api.nvim_create_user_command("MarkdownTablePreview", function()
    M.preview()
  end, { desc = "Preview the Markdown pipe table under the cursor with wrapped cells", force = true })

  vim.api.nvim_create_user_command("MarkdownTableInlinePreview", function()
    M.inline_preview()
  end, { desc = "Inline preview the Markdown pipe table under the cursor with wrapped cells", force = true })

  vim.api.nvim_create_user_command("MarkdownTableFloatPreview", function()
    M.float_preview()
  end, { desc = "Floating preview the Markdown pipe table under the cursor with wrapped cells", force = true })

  vim.api.nvim_create_user_command("MarkdownTableTogglePreview", function()
    M.toggle_preview()
  end, { desc = "Toggle wrapped Markdown table preview", force = true })

  vim.api.nvim_create_user_command("MarkdownTableClosePreview", function()
    M.close_preview()
  end, { desc = "Close wrapped Markdown table preview", force = true })

  vim.api.nvim_create_user_command("MarkdownTableRefresh", function()
    M.refresh_auto({ force = true })
  end, { desc = "Force refresh Markdown table rendering", force = true })

  vim.api.nvim_create_user_command("MarkdownTableEnableAutoPreview", function()
    M.enable_auto_preview()
  end, { desc = "Enable automatic Markdown table preview in the current buffer", force = true })

  vim.api.nvim_create_user_command("MarkdownTableDisableAutoPreview", function()
    M.disable_auto_preview()
  end, { desc = "Disable automatic Markdown table preview in the current buffer", force = true })

  vim.api.nvim_create_user_command("MarkdownTableToggleAutoPreview", function()
    M.toggle_auto_preview()
  end, { desc = "Toggle automatic Markdown table preview in the current buffer", force = true })

  vim.api.nvim_create_user_command("MarkdownTableStatus", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local active = require("markdown-table-wrap.inline").is_active(bufnr)
    local paused = M.state.paused_buffers[bufnr] == true
    vim.notify(
      string.format(
        "MarkdownTableWrap: auto=%s paused=%s active=%s mode=%s/%s",
        tostring(M.config.auto_preview),
        tostring(paused),
        tostring(active),
        M.config.preview_mode,
        M.config.inline_mode .. (M.config.inline_viewport_scrolling and "/viewport" or "/full")
      ),
      vim.log.levels.INFO
    )
  end, { desc = "Show Markdown table wrap status", force = true })

  vim.api.nvim_create_user_command("MarkdownTableToggleInlineViewport", function()
    M.toggle_inline_viewport_scrolling()
  end, { desc = "Toggle inline viewport scrolling for long rendered tables", force = true })

  vim.api.nvim_create_user_command("MarkdownTableNextCell", function()
    require("markdown-table-wrap.nav").move_horizontal(1)
  end, { desc = "Move to the next Markdown table cell", force = true })

  vim.api.nvim_create_user_command("MarkdownTablePrevCell", function()
    require("markdown-table-wrap.nav").move_horizontal(-1)
  end, { desc = "Move to the previous Markdown table cell", force = true })

  vim.api.nvim_create_user_command("MarkdownTableNextRow", function()
    require("markdown-table-wrap.nav").move_vertical(1)
  end, { desc = "Move to the same Markdown table cell in the next row", force = true })

  vim.api.nvim_create_user_command("MarkdownTablePrevRow", function()
    require("markdown-table-wrap.nav").move_vertical(-1)
  end, { desc = "Move to the same Markdown table cell in the previous row", force = true })

  vim.api.nvim_create_user_command("MarkdownTableEditCell", function()
    require("markdown-table-wrap.edit").edit_cell()
  end, { desc = "Edit the current Markdown table cell in a floating window", force = true })

  vim.api.nvim_create_user_command("MarkdownTableFocus", function()
    require("markdown-table-wrap.view").focus()
  end, { desc = "Enter the rendered table for native cursor navigation", force = true })

  vim.api.nvim_create_user_command("MarkdownTableCreate", function()
    M.create_table()
  end, { desc = "Insert a new one-column Markdown table below the cursor", force = true })

  vim.api.nvim_create_user_command("MarkdownTableOpenLink", function()
    require("markdown-table-wrap.nav").open_link()
  end, { desc = "Open the first link in the current Markdown table cell", force = true })

  vim.api.nvim_create_user_command("MarkdownTableScrollDown", function(opts_cmd)
    local count = tonumber(opts_cmd.count) or 1
    M.scroll_view(count > 0 and count or 1)
  end, { desc = "Scroll rendered Markdown table view down", count = true, force = true })

  vim.api.nvim_create_user_command("MarkdownTableScrollUp", function(opts_cmd)
    local count = tonumber(opts_cmd.count) or 1
    M.scroll_view(-(count > 0 and count or 1))
  end, { desc = "Scroll rendered Markdown table view up", count = true, force = true })

  vim.api.nvim_create_user_command("MarkdownTableScrollTop", function()
    M.scroll_view_to("top")
  end, { desc = "Scroll rendered Markdown table view to the top", force = true })

  vim.api.nvim_create_user_command("MarkdownTableScrollBottom", function()
    M.scroll_view_to("bottom")
  end, { desc = "Scroll rendered Markdown table view to the bottom", force = true })

  if M.config.auto_preview and is_markdown_buffer() then
    M.schedule_refresh({ silent = true, immediate = true })
  end
end

return M
