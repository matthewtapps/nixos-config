-- Turn markdown lines into extmark virt_lines chunks.
--
-- Virtual lines never pass through treesitter, so render-markdown.nvim cannot
-- style them — this is a hand-rolled approximation that reuses render-markdown's
-- highlight groups (with treesitter fallbacks) so embeds match the buffer's
-- look.

local M = {}

-- Each entry is tried in order; the first group that exists wins. The last
-- entry is always a builtin/treesitter group so links never dangle.
local HL_FALLBACKS = {
	TranscludeBorder = { "RenderMarkdownQuote", "NonText" },
	TranscludeTitle = { "RenderMarkdownLink", "@markup.link.label" },
	TranscludeMuted = { "Comment" },
	TranscludeError = { "DiagnosticWarn" },
	TranscludeCode = { "RenderMarkdownCodeInline", "@markup.raw" },
	TranscludeCodeBlock = { "RenderMarkdownCode", "ColorColumn" },
	TranscludeBold = { "@markup.strong" },
	TranscludeItalic = { "@markup.italic" },
	TranscludeLink = { "RenderMarkdownLink", "@markup.link.label" },
	TranscludeQuote = { "RenderMarkdownQuote", "@markup.quote" },
	TranscludeBullet = { "RenderMarkdownBullet", "@markup.list" },
	TranscludeH1 = { "RenderMarkdownH1", "@markup.heading.1" },
	TranscludeH2 = { "RenderMarkdownH2", "@markup.heading.2" },
	TranscludeH3 = { "RenderMarkdownH3", "@markup.heading.3" },
	TranscludeH4 = { "RenderMarkdownH4", "@markup.heading.4" },
	TranscludeH5 = { "RenderMarkdownH5", "@markup.heading.5" },
	TranscludeH6 = { "RenderMarkdownH6", "@markup.heading.6" },
}

function M.define_highlights()
	for name, targets in pairs(HL_FALLBACKS) do
		local target = targets[#targets]
		for _, t in ipairs(targets) do
			if vim.fn.hlexists(t) == 1 then
				target = t
				break
			end
		end
		vim.api.nvim_set_hl(0, name, { link = target, default = true })
	end
end

local HEADING_ICONS = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " }
local BULLET_ICONS = { "● ", "○ ", "◆ ", "◇ " }

---Split inline markdown into styled chunks.
---@param text string
---@param base string base highlight for unstyled spans
---@return [string, string][]
local function inline(text, base)
	local patterns = {
		{ "`([^`]+)`", "TranscludeCode" },
		{ "%*%*([^%*]+)%*%*", "TranscludeBold" },
		{ "%*([^%*]+)%*", "TranscludeItalic" },
		{ "_([^_]+)_", "TranscludeItalic" },
		{ "%[%[([^%[%]]+)%]%]", "TranscludeLink", wikilink = true },
		{ "%[([^%]]+)%]%([^%)]*%)", "TranscludeLink" },
	}
	local chunks, pos = {}, 1
	while pos <= #text do
		local best, best_s, best_e, best_cap
		for _, p in ipairs(patterns) do
			local s, e, cap = text:find(p[1], pos)
			if s and (not best_s or s < best_s) then
				best, best_s, best_e, best_cap = p, s, e, cap
			end
		end
		if not best then
			chunks[#chunks + 1] = { text:sub(pos), base }
			break
		end
		if best_s > pos then
			chunks[#chunks + 1] = { text:sub(pos, best_s - 1), base }
		end
		local display = best_cap
		if best.wikilink then
			-- [[target|alias]] shows the alias; [[target#anchor]] shows the target.
			display = best_cap:match("|(.*)$") or best_cap:gsub("#.*$", "")
			display = "󰌷 " .. display
		end
		chunks[#chunks + 1] = { display, best[2] }
		pos = best_e + 1
	end
	if #chunks == 0 then
		chunks[1] = { "", base }
	end
	return chunks
end

---Style one markdown line. `state` carries the code-fence flag across lines.
---@param line string
---@param state { in_code: boolean }
---@return [string, string][]
function M.style_line(line, state)
	local fence = line:match("^%s*```(.*)$")
	if fence then
		state.in_code = not state.in_code
		local label = state.in_code and (" " .. (vim.trim(fence) ~= "" and vim.trim(fence) or "code")) or ""
		return { { label ~= "" and ("󰅩" .. label) or " ", "TranscludeMuted" } }
	end
	if state.in_code then
		return { { line ~= "" and line or " ", "TranscludeCodeBlock" } }
	end
	local hashes, htext = line:match("^(#+)%s+(.*)$")
	if hashes then
		local level = math.min(#hashes, 6)
		local hl = "TranscludeH" .. level
		local chunks = { { HEADING_ICONS[level], hl } }
		vim.list_extend(chunks, inline(htext, hl))
		return chunks
	end
	local qtext = line:match("^>%s?(.*)$")
	if qtext then
		local chunks = { { "▋ ", "TranscludeQuote" } }
		vim.list_extend(chunks, inline(qtext, "TranscludeQuote"))
		return chunks
	end
	local indent, box, item = line:match("^(%s*)[-%*+] %[(.)%] (.*)$")
	if box then
		local icon = (box == " " and "󰄱 " or "󰱒 ")
		local chunks = { { indent .. icon, "TranscludeBullet" } }
		vim.list_extend(chunks, inline(item, box ~= " " and "TranscludeMuted" or "Normal"))
		return chunks
	end
	local lindent, ltext = line:match("^(%s*)[-%*+] (.*)$")
	if ltext then
		local level = (math.floor(#lindent / 2) % #BULLET_ICONS) + 1
		local chunks = { { lindent .. BULLET_ICONS[level], "TranscludeBullet" } }
		vim.list_extend(chunks, inline(ltext, "Normal"))
		return chunks
	end
	if line:match("^%s*%-%-%-+%s*$") or line:match("^%s*%*%*%*+%s*$") then
		return { { ("─"):rep(40), "TranscludeMuted" } }
	end
	if line == "" then
		return { { " ", "Normal" } }
	end
	return inline(line, "Normal")
end

---Title line chunks for an embed header.
---@param display string note name (or alias) to show
---@param anchor string|nil heading/block anchor for the subtitle
---@return [string, string][]
function M.title(display, anchor)
	local chunks = { { "󰈔 ", "TranscludeTitle" }, { display, "TranscludeTitle" } }
	if anchor then
		chunks[#chunks + 1] = { " › " .. anchor, "TranscludeMuted" }
	end
	return chunks
end

local function chunks_width(chunks)
	local w = 0
	for _, c in ipairs(chunks) do
		w = w + vim.fn.strdisplaywidth(c[1])
	end
	return w
end

-- Chunks whose display width should become the hanging indent of continuation
-- lines, so wrapped text aligns under the content, not the marker.
local HANGING = {
	TranscludeBullet = true,
	TranscludeQuote = true,
	TranscludeH1 = true,
	TranscludeH2 = true,
	TranscludeH3 = true,
	TranscludeH4 = true,
	TranscludeH5 = true,
	TranscludeH6 = true,
}

---Soft-wrap one virt line's chunks to `width` columns. virt_lines ignore the
---window 'wrap' option and truncate at the edge, so wrapping is on us.
---@param chunks [string, string][]
---@param width integer
---@return [string, string][][]
local function wrap_line(chunks, width)
	-- Border chunks repeat verbatim on every continuation line.
	local prefix, i = {}, 1
	while chunks[i] and chunks[i][2] == "TranscludeBorder" do
		prefix[#prefix + 1] = chunks[i]
		i = i + 1
	end
	local hang = ""
	local first = chunks[i]
	if first and HANGING[first[2]] then
		local w = vim.fn.strdisplaywidth(first[1])
		if w <= 8 then
			hang = (" "):rep(w)
		end
	end

	local avail = width - chunks_width(prefix)
	if avail < 10 or chunks_width(chunks) <= width then
		return { chunks }
	end

	local lines, cur, curw = {}, {}, 0
	local function flush()
		lines[#lines + 1] = cur
		cur, curw = {}, 0
	end
	local function push(text, hl)
		cur[#cur + 1] = { text, hl }
		curw = curw + vim.fn.strdisplaywidth(text)
	end
	for j = i, #chunks do
		local text, hl = chunks[j][1], chunks[j][2]
		for space, word in text:gmatch("(%s*)(%S+)") do
			local max = #lines == 0 and avail or (avail - #hang)
			local token = space .. word
			if curw > 0 and curw + vim.fn.strdisplaywidth(token) > max then
				flush()
				token = word -- drop the leading space at a fold point
			end
			-- Hard-split anything wider than a whole line (URLs, long code).
			while vim.fn.strdisplaywidth(token) > max - curw do
				local head = vim.fn.strcharpart(token, 0, max - curw)
				push(head, hl)
				token = token:sub(#head + 1)
				flush()
			end
			if token ~= "" then
				push(token, hl)
			end
		end
		-- gmatch only yields space-then-word pairs, so a chunk's trailing
		-- whitespace (e.g. the space in a "● " marker) would vanish — restore it.
		local trail = text:match("(%s+)$")
		if trail and curw > 0 then
			push(trail, hl)
		end
	end
	if #cur > 0 then
		flush()
	end
	if #lines == 0 then
		return { chunks }
	end

	local out = {}
	for k, body in ipairs(lines) do
		local line = vim.list_extend({}, prefix)
		if k > 1 and hang ~= "" then
			line[#line + 1] = { hang, "Normal" }
		end
		vim.list_extend(line, body)
		out[#out + 1] = line
	end
	return out
end

---Wrap all virt lines to fit `width` columns.
---@param virt_lines [string, string][][]
---@param width integer
---@return [string, string][][]
function M.wrap(virt_lines, width)
	local out = {}
	for _, chunks in ipairs(virt_lines) do
		vim.list_extend(out, wrap_line(chunks, width))
	end
	return out
end

---Prefix every virt line with one border chunk per nesting level.
---@param virt_lines [string, string][][]
---@param opts { border: string }
---@return [string, string][][]
function M.borderize(virt_lines, opts)
	for _, chunks in ipairs(virt_lines) do
		table.insert(chunks, 1, { opts.border .. " ", "TranscludeBorder" })
	end
	return virt_lines
end

return M
