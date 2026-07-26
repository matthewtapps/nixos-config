-- Link resolution and content extraction for Obsidian-style embeds.
--
-- Obsidian resolves `[[name]]` by basename anywhere in the vault, so we keep a
-- cached basename → path index built from a single glob. The cache is
-- invalidated on any markdown write (see init.lua) rather than watched, which
-- is cheap and always correct enough for interactive editing.

local M = {}

---@class transclude.Spec
---@field name string file part, "" means current file
---@field heading string|nil `#Heading` anchor
---@field block string|nil `#^blockid` anchor
---@field alias string|nil display text after `|`

---Parse the inside of `![[...]]`.
---@param target string
---@return transclude.Spec
function M.parse(target)
	local link = target
	local alias = link:match("|(.*)$")
	if alias then
		link = link:sub(1, #link - #alias - 1)
	end
	local name, anchor = link:match("^([^#]*)#(.*)$")
	name = name or link
	local block, heading
	if anchor then
		block = anchor:match("^%^(.+)$")
		heading = not block and anchor or nil
	end
	return { name = vim.trim(name), heading = heading, block = block, alias = alias }
end

---Vault root for a buffer. Prefer obsidian.nvim's active workspace, then an
---upward `.obsidian` marker, then the buffer's own directory.
---@param bufname string
---@return string
function M.vault_root(bufname)
	-- Community-fork obsidian.nvim ≥3.x exposes the active workspace globally.
	local ws = _G.Obsidian and _G.Obsidian.workspace
	if ws and ws.path then
		return vim.fs.normalize(tostring(ws.path))
	end
	local dir = vim.fs.dirname(bufname)
	local marker = vim.fs.find(".obsidian", { upward = true, path = dir, type = "directory" })[1]
	if marker then
		return vim.fs.dirname(marker)
	end
	return dir
end

local cache = { root = nil, by_base = nil, by_rel = nil }

function M.invalidate()
	cache.by_base = nil
end

local function index(root)
	if cache.by_base and cache.root == root then
		return cache.by_base, cache.by_rel
	end
	local by_base, by_rel = {}, {}
	for _, path in ipairs(vim.fn.globpath(root, "**/*.md", true, true)) do
		path = vim.fs.normalize(path)
		local rel = path:sub(#root + 2)
		by_rel[rel:lower()] = path
		local base = vim.fs.basename(path):gsub("%.md$", ""):lower()
		-- First match wins, mirroring Obsidian's "shortest path when possible"
		-- resolution closely enough for non-duplicate basenames.
		if not by_base[base] then
			by_base[base] = path
		end
	end
	cache.root, cache.by_base, cache.by_rel = root, by_base, by_rel
	return by_base, by_rel
end

---Resolve a link name to an absolute path.
---@param name string link target without anchor/alias ("" = current file)
---@param cur_path string absolute path of the file containing the embed
---@return string|nil
function M.path_for(name, cur_path)
	if name == "" then
		return cur_path
	end
	local root = M.vault_root(cur_path)
	local by_base, by_rel = index(root)
	local key = name:lower():gsub("%.md$", "")
	return by_rel[key .. ".md"] or by_base[vim.fs.basename(key)]
end

---@param path string
---@return string[]|nil
function M.read_lines(path)
	-- Prefer the loaded buffer so unsaved edits transclude live.
	local buf = vim.fn.bufnr(path)
	if buf ~= -1 and vim.api.nvim_buf_is_loaded(buf) then
		return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	end
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local content = f:read("*a")
	f:close()
	return vim.split(content, "\n", { plain = true })
end

local function strip_frontmatter(lines)
	if lines[1] ~= "---" then
		return lines
	end
	for i = 2, #lines do
		if lines[i] == "---" then
			return vim.list_slice(lines, i + 1)
		end
	end
	return lines
end

-- Obsidian heading links ignore case and inline formatting; normalize both
-- sides the same way before comparing.
local function norm_heading(s)
	return vim.trim(s:gsub("[%*_`%[%]]", "")):lower()
end

---@param lines string[]
---@param spec transclude.Spec
---@return string[]|nil extracted lines, nil when the anchor is missing
function M.extract(lines, spec)
	lines = strip_frontmatter(lines)
	if spec.heading then
		local want = norm_heading(spec.heading)
		local start, level
		for i, line in ipairs(lines) do
			local hashes, text = line:match("^(#+)%s+(.*)$")
			if hashes then
				if start and #hashes <= level then
					return vim.list_slice(lines, start, i - 1)
				end
				if not start and norm_heading(text) == want then
					start, level = i, #hashes
				end
			end
		end
		return start and vim.list_slice(lines, start, #lines) or nil
	end
	if spec.block then
		local pat = "%^" .. vim.pesc(spec.block) .. "%s*$"
		for i, line in ipairs(lines) do
			if line:match(pat) then
				-- A lone `^id` line labels the paragraph above it.
				local anchor = i
				if vim.trim(line) == "^" .. spec.block then
					anchor = i - 1
				end
				local first, last = anchor, anchor
				while first > 1 and vim.trim(lines[first - 1]) ~= "" and not lines[first - 1]:match("^#+%s") do
					first = first - 1
				end
				while last < #lines and vim.trim(lines[last + 1]) ~= "" and not lines[last + 1]:match("^#+%s") do
					last = last + 1
				end
				local out = vim.list_slice(lines, first, last)
				for j, l in ipairs(out) do
					out[j] = l:gsub("%s*%^" .. vim.pesc(spec.block) .. "%s*$", "")
				end
				return out
			end
		end
		return nil
	end
	-- Whole-file embed: trim leading/trailing blank lines.
	local first, last = 1, #lines
	while first <= last and vim.trim(lines[first]) == "" do
		first = first + 1
	end
	while last >= first and vim.trim(lines[last]) == "" do
		last = last - 1
	end
	return vim.list_slice(lines, first, last)
end

return M
