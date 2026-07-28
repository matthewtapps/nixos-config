-- Obsidian-style transclusion for Neovim.
--
-- Renders `![[note]]`, `![[note#Heading]]` and `![[note#^block]]` embeds as
-- virtual lines below the embed line, styled to match render-markdown.nvim.
-- The raw `![[...]]` text is covered by a header overlay except when the
-- cursor is on that line (same anti-conceal philosophy as render-markdown), so
-- following the link stays trivial: put the cursor on the line and use
-- obsidian.nvim's smart action / `:Obsidian follow_link`.

local resolve = require("transclude.resolve")
local render = require("transclude.render")

local M = {}

M.config = {
	enabled = true,
	max_lines = 40, -- cap per embed after composing nested content
	max_depth = 3, -- how deep nested embeds recurse before showing a stub
	hide_raw = true, -- overlay the header on the raw line when cursor is elsewhere
	border = "▏",
	-- Embeds of these extensions are left alone (images belong to snacks.image
	-- / obsidian.nvim, not us).
	exclude = { "png", "jpg", "jpeg", "gif", "webp", "svg", "bmp", "pdf", "mp4", "mp3", "wav" },
}

local ns_lines = vim.api.nvim_create_namespace("transclude.lines")
local ns_overlay = vim.api.nvim_create_namespace("transclude.overlay")

-- Per-buffer render state: mark_id → { title = chunks } for overlay management.
local state = {} ---@type table<integer, { embeds: table<integer, { title: [string,string][] }>, overlays: table<integer, integer> }>

local excluded = {}
local function is_excluded(name)
	local ext = name:match("%.(%w+)$")
	return ext and excluded[ext:lower()] or false
end

---Compose the virt_lines for one embed target, recursing into nested embeds.
---@param target string inside of `![[...]]`
---@param cur_path string file containing the embed
---@param depth integer
---@param visited table<string, boolean>
---@return [string,string][][] virt lines (without border prefixes)
local function compose(target, cur_path, depth, visited)
	local spec = resolve.parse(target)
	local path = resolve.path_for(spec.name, cur_path)
	if not path then
		return { { { "󰋔 unresolved: " .. spec.name, "TranscludeError" } } }
	end
	local anchor = spec.heading or (spec.block and "^" .. spec.block)
	local key = path .. "#" .. (anchor or "")
	if visited[key] then
		return { { { "↺ cycle: " .. spec.name, "TranscludeMuted" } } }
	end
	visited[key] = true

	local lines = resolve.read_lines(path)
	local content = lines and resolve.extract(lines, spec)
	if not content then
		visited[key] = nil
		return { { { ("󰋔 missing anchor: %s#%s"):format(spec.name, anchor or ""), "TranscludeError" } } }
	end

	local display = spec.alias or (spec.name ~= "" and spec.name) or vim.fs.basename(path):gsub("%.md$", "")
	-- At depth 0 the raw-line overlay already shows this header (and with the
	-- cursor on the line, the raw ![[...]] is self-describing) — a title
	-- virt_line would just duplicate it. Nested embeds have no overlay, so
	-- they keep theirs.
	local out = {}
	if depth > 0 or not M.config.hide_raw then
		out[1] = render.title(display, anchor)
	end
	local fence_state = { in_code = false }
	for _, line in ipairs(content) do
		local nested = line:match("^%s*!%[%[([^%[%]]+)%]%]%s*$")
		if nested and not is_excluded(resolve.parse(nested).name) and not fence_state.in_code then
			if depth < M.config.max_depth then
				vim.list_extend(out, render.borderize(compose(nested, path, depth + 1, visited), M.config))
			else
				out[#out + 1] = { { "↪ " .. nested .. " (max depth)", "TranscludeMuted" } }
			end
		else
			if not fence_state.in_code then
				-- Obsidian hides block-id markers (`^abc123`) in preview; do the same.
				line = line:gsub("%s+%^[%w%-]+%s*$", "")
			end
			out[#out + 1] = render.style_line(line, fence_state)
		end
	end
	visited[key] = nil

	if depth == 0 and #out > M.config.max_lines then
		local dropped = #out - M.config.max_lines
		out = vim.list_slice(out, 1, M.config.max_lines)
		out[#out + 1] = { { ("… +%d more lines"):format(dropped), "TranscludeMuted" } }
	end
	return out
end

---Usable text width for a buffer: narrowest window showing it, minus gutter
---(number/sign columns). Falls back to 80 when the buffer has no window yet.
local function text_width(buf)
	local width
	for _, win in ipairs(vim.fn.win_findbuf(buf)) do
		local info = vim.fn.getwininfo(win)[1]
		local w = vim.api.nvim_win_get_width(win) - (info and info.textoff or 0)
		if not width or w < width then
			width = w
		end
	end
	return width or 80
end

local function set_overlay(buf, mark_id, row)
	local st = state[buf]
	local embed = st.embeds[mark_id]
	if not embed then
		return
	end
	local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
	-- Pad the header to the raw line's full display width so no source text
	-- peeks out past the overlay (works at any conceallevel).
	local chunks = vim.deepcopy(embed.title)
	local width = 0
	for _, c in ipairs(chunks) do
		width = width + vim.fn.strdisplaywidth(c[1])
	end
	local pad = vim.fn.strdisplaywidth(line) - width
	if pad > 0 then
		chunks[#chunks + 1] = { (" "):rep(pad), "Normal" }
	end
	st.overlays[mark_id] = vim.api.nvim_buf_set_extmark(buf, ns_overlay, row, 0, {
		id = st.overlays[mark_id],
		virt_text = chunks,
		virt_text_pos = "overlay",
		hl_mode = "combine",
	})
end

---Re-evaluate which raw lines should be covered, based on cursor position.
local function update_overlays(buf)
	local st = state[buf]
	if not st then
		return
	end
	local cursor_row
	if vim.api.nvim_get_current_buf() == buf then
		cursor_row = vim.api.nvim_win_get_cursor(0)[1] - 1
	end
	for mark_id in pairs(st.embeds) do
		local pos = vim.api.nvim_buf_get_extmark_by_id(buf, ns_lines, mark_id, {})
		local row = pos and pos[1]
		local want = M.config.hide_raw and row ~= nil and row ~= cursor_row
		if want then
			set_overlay(buf, mark_id, row)
		elseif st.overlays[mark_id] then
			vim.api.nvim_buf_del_extmark(buf, ns_overlay, st.overlays[mark_id])
			st.overlays[mark_id] = nil
		end
	end
end

function M.render(buf)
	buf = buf or vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	vim.api.nvim_buf_clear_namespace(buf, ns_lines, 0, -1)
	vim.api.nvim_buf_clear_namespace(buf, ns_overlay, 0, -1)
	state[buf] = { embeds = {}, overlays = {} }
	if not M.config.enabled then
		return
	end
	render.define_highlights()

	local cur_path = vim.fs.normalize(vim.api.nvim_buf_get_name(buf))
	local width = text_width(buf)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local fence_state = { in_code = false }
	for i, line in ipairs(lines) do
		if line:match("^%s*```") then
			fence_state.in_code = not fence_state.in_code
		end
		local target = line:match("^%s*!%[%[([^%[%]]+)%]%]%s*$")
		if target and not fence_state.in_code and not is_excluded(resolve.parse(target).name) then
			local virt = render.wrap(render.borderize(compose(target, cur_path, 0, {}), M.config), width)
			local mark_id = vim.api.nvim_buf_set_extmark(buf, ns_lines, i - 1, 0, {
				virt_lines = virt,
			})
			local spec = resolve.parse(target)
			local anchor = spec.heading or (spec.block and "^" .. spec.block)
			state[buf].embeds[mark_id] = {
				title = render.title(spec.alias or spec.name, anchor),
			}
		end
	end
	update_overlays(buf)
end

-- One long-lived timer per buffer. Restarting a pending timer just resets its
-- deadline, so debouncing never closes a handle that still has a callback in
-- flight — the handle is only closed once, when the buffer goes away.
local timers = {}

local function stop_timer(buf)
	local timer = timers[buf]
	if timer then
		timers[buf] = nil
		timer:stop()
		timer:close()
	end
end

local function debounced_render(buf)
	local timer = timers[buf]
	if not timer then
		timer = vim.uv.new_timer()
		timers[buf] = timer
	end
	timer:start(
		150,
		0,
		vim.schedule_wrap(function()
			if vim.api.nvim_buf_is_valid(buf) then
				M.render(buf)
			else
				stop_timer(buf)
			end
		end)
	)
end

local function attach(buf)
	if vim.b[buf].transclude_attached then
		return
	end
	vim.b[buf].transclude_attached = true
	local group = vim.api.nvim_create_augroup("TranscludeBuf" .. buf, { clear = true })
	vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave", "BufWinEnter" }, {
		group = group,
		buffer = buf,
		callback = function()
			debounced_render(buf)
		end,
	})
	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		group = group,
		buffer = buf,
		callback = function()
			update_overlays(buf)
		end,
	})
	vim.api.nvim_create_autocmd("BufDelete", {
		group = group,
		buffer = buf,
		callback = function()
			state[buf] = nil
			stop_timer(buf)
			vim.api.nvim_del_augroup_by_id(group)
		end,
	})
	M.render(buf)
end

function M.toggle()
	M.config.enabled = not M.config.enabled
	for buf in pairs(state) do
		if vim.api.nvim_buf_is_valid(buf) then
			M.render(buf)
		end
	end
	vim.notify("transclude: " .. (M.config.enabled and "on" or "off"))
end

function M.refresh()
	resolve.invalidate()
	for buf in pairs(state) do
		if vim.api.nvim_buf_is_valid(buf) then
			M.render(buf)
		end
	end
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
	excluded = {}
	for _, ext in ipairs(M.config.exclude) do
		excluded[ext] = true
	end

	local group = vim.api.nvim_create_augroup("Transclude", { clear = true })
	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		pattern = { "markdown", "markdown.mdx" },
		callback = function(ev)
			attach(ev.buf)
		end,
	})
	-- Edits to any note invalidate the file index and re-render attached
	-- buffers, so embeds track their sources.
	vim.api.nvim_create_autocmd("BufWritePost", {
		group = group,
		pattern = "*.md",
		callback = M.refresh,
	})
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = group,
		callback = render.define_highlights,
	})
	-- Wrapping is computed against window width, so layout changes need a
	-- re-render of every visible attached buffer.
	vim.api.nvim_create_autocmd({ "WinResized", "VimResized" }, {
		group = group,
		callback = function()
			for buf in pairs(state) do
				if vim.api.nvim_buf_is_valid(buf) and #vim.fn.win_findbuf(buf) > 0 then
					debounced_render(buf)
				end
			end
		end,
	})

	vim.api.nvim_create_user_command("Transclude", function(cmd)
		local sub = cmd.args ~= "" and cmd.args or "toggle"
		if sub == "toggle" then
			M.toggle()
		elseif sub == "refresh" then
			M.refresh()
		elseif sub == "enable" then
			M.config.enabled = true
			M.refresh()
		elseif sub == "disable" then
			M.config.enabled = false
			M.refresh()
		end
	end, {
		nargs = "?",
		complete = function()
			return { "toggle", "refresh", "enable", "disable" }
		end,
	})

	-- Attach to markdown buffers that are already open (setup runs lazily on
	-- the first markdown FileType, whose autocmd above may have already fired).
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype:find("^markdown") then
			attach(buf)
		end
	end
end

return M
