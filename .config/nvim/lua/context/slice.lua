-- lua/context/slice.lua
--
-- Three-tier extraction: Tree-sitter → heuristic window → full file (capped)

local M, ts = {}, vim.treesitter

-----------------------------------------------------------
-- Config
-----------------------------------------------------------
local cfg = {
	skip_patterns = { "node_modules", "%.d%.ts$" },
	context_window = 30,
	full_file_line_cap = 800,
}
local LANGS = { "typescript", "tsx", "javascript", "js" }
local RAW_QUERY = [[
  (identifier) @id
  (property_identifier) @id
  (type_identifier) @id
]]

-----------------------------------------------------------
-- Helpers
-----------------------------------------------------------
local function skip_path(p)
	for _, pat in ipairs(cfg.skip_patterns) do
		if p:find(pat) then
			return true
		end
	end
end
local function load_buf(p)
	local ok, b = pcall(vim.fn.bufnr, p, true)
	if not ok or b < 1 then
		return nil
	end
	if not vim.api.nvim_buf_is_loaded(b) then
		if not pcall(vim.fn.bufload, b) then
			return nil
		end
	end
	return b
end
local function lcase(s)
	return s and s:lower() or ""
end

local qcache = {}
local function get_query(lang)
	if not qcache[lang] then
		local ok, q = pcall(ts.query.parse, lang, RAW_QUERY)
		if ok then
			qcache[lang] = q
		end
	end
	return qcache[lang]
end

local function ascend(node)
	while node and node:parent() do
		local t = node:type()
		if t:find("declaration") or t:find("function") then
			return node
		end
		node = node:parent()
	end
	return node
end

local function slice_full(bufnr, file, symbol)
	local total = vim.api.nvim_buf_line_count(bufnr)
	local cap = math.min(total, cfg.full_file_line_cap)
	return {
		file = file,
		symbol = symbol,
		node_type = "file",
		start_line = 1,
		end_line = cap,
		text = vim.api.nvim_buf_get_lines(bufnr, 0, cap, false),
	}
end

-----------------------------------------------------------
-- Main
-----------------------------------------------------------
function M.extract_code_for_symbol(file, symbol)
	if skip_path(file) then
		return nil
	end
	local bufnr = load_buf(file)
	if not bufnr then
		return nil
	end

	-- choose parser / query
	local parser, query
	for _, lang in ipairs(LANGS) do
		local ok, p = pcall(ts.get_parser, bufnr, lang)
		if ok and p then
			parser = p
			query = get_query(lang)
			break
		end
	end
	if not parser or not query then
		return slice_full(bufnr, file, symbol)
	end

	local root = parser:parse()[1]:root()

	-- 1. Tree-sitter identifier capture
	for _, node in query:iter_captures(root, bufnr, 0, -1) do
		local txt = ts.get_node_text(node, bufnr)
		if txt and (txt == symbol or lcase(txt) == lcase(symbol)) then
			node = ascend(node)
			if node then
				local sr, _, er, _ = node:range()
				return {
					file = file,
					symbol = symbol,
					node_type = node:type(),
					start_line = sr + 1,
					end_line = er + 1,
					text = vim.api.nvim_buf_get_lines(bufnr, sr, er + 1, false),
				}
			end
		end
	end

	-- 2. Heuristic ±N lines around first textual hit
	local pos = vim.fn.searchpos("\\V" .. symbol, "nw", cfg.full_file_line_cap)
	if pos[1] > 0 then
		local lnum = pos[1] - 1
		local s = math.max(0, lnum - cfg.context_window)
		local e = math.min(vim.api.nvim_buf_line_count(bufnr), lnum + cfg.context_window)
		return {
			file = file,
			symbol = symbol,
			node_type = "heuristic",
			start_line = s + 1,
			end_line = e,
			text = vim.api.nvim_buf_get_lines(bufnr, s, e, false),
		}
	end

	-- 3. Full-file fallback
	return slice_full(bufnr, file, symbol)
end

return M
