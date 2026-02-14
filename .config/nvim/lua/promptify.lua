-- promptify.lua — TypeScript slice-hoister (v0.5.1-full)
-- ---------------------------------------------------------------------------
-- Slices **any** symbol (identifier, type, interface, class, method, function)
-- into a flat, self-contained snippet: imports ➜ transitive module-level
-- dependencies ➜ entry symbol. Ready to feed an LLM.
-- ---------------------------------------------------------------------------
-- NEW IN 0.5.1
--   • Multi-strategy symbol resolution (definition → typeDefinition →
--     implementation → first out-of-file reference).
--   • Longer LSP timeout (1.5 s) and depth 5 (configurable).
--   • Hoists top-of-file import lines so decorators/side-effect deps aren’t
--     missed.
--   • Provenance headers `// -- path:line --` for every hoisted block.
--   • Zero duplicates: keyed by exact text.
-- ---------------------------------------------------------------------------
local api, fn = vim.api, vim.fn
local ts = vim.treesitter
local ts_utils = require("nvim-treesitter.ts_utils")
local lsp_util = vim.lsp.util

local M = {}

M.opts = {
	max_depth = 5,
	snippet_limit = 4096,
	prompt_limit = 80000,
	containers = {
		function_declaration = true,
		method_definition = true,
		function_expression = true,
		variable_declaration = true,
		lexical_declaration = true,
		class_declaration = true,
		interface_declaration = true,
		enum_declaration = true,
		type_alias_declaration = true,
	},
}

function M.setup(opts)
	M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})
	api.nvim_create_user_command("PromptifySlice", M.run, { desc = "Slice current TS symbol with deps" })
end

-----------------------------------------------------------------------
-- LSP helpers ---------------------------------------------------------
-----------------------------------------------------------------------
local function buf_encoding(bufnr)
	for _, c in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
		if c.offset_encoding then
			return c.offset_encoding
		end
	end
	return "utf-16"
end

local function make_params(bufnr, pos)
	local win = api.nvim_get_current_win()
	local params = lsp_util.make_position_params(win, buf_encoding(bufnr))
	params.textDocument.uri = vim.uri_from_bufnr(bufnr)
	params.position = pos
	return params
end

local function lsp_sync(method, params)
	local res, done
	vim.lsp.buf_request(0, method, params, function(err, resp)
		if not err then
			res = resp
		end
		done = true
	end)
	vim.wait(1500, function()
		return done
	end, 10, false)
	return res
end

---definition → typeDefinition → implementation → first external reference
local DEF_ORDER = {
	"textDocument/definition",
	"textDocument/typeDefinition",
	"textDocument/implementation",
}
local function best_definition(bufnr, pos)
	for _, m in ipairs(DEF_ORDER) do
		local r = lsp_sync(m, make_params(bufnr, pos))
		if type(r) == "table" and r[1] then
			return r[1]
		end
	end
	local refs = lsp_sync(
		"textDocument/references",
		vim.tbl_extend("force", make_params(bufnr, pos), { context = { includeDeclaration = true } })
	)
	if type(refs) == "table" then
		local uri0 = vim.uri_from_bufnr(bufnr)
		for _, loc in ipairs(refs) do
			if (loc.uri or loc.targetUri) ~= uri0 then
				return loc
			end
		end
	end
end

-----------------------------------------------------------------------
-- Treesitter helpers --------------------------------------------------
-----------------------------------------------------------------------
local function node_text(n, b)
	return ts.get_node_text(n, b)
end
local function container(n)
	while n and not M.opts.containers[n:type()] do
		n = n:parent()
	end
	return n
end
local function is_module_level(n)
	return n and n:parent() and n:parent():type() == "program"
end
local function each_identifier(root, cb)
	local function walk(n)
		if n:type() == "identifier" then
			cb(n)
		end
		for child in n:iter_children() do
			walk(child)
		end
	end
	walk(root)
end

-----------------------------------------------------------------------
-- Import scraper ------------------------------------------------------
-----------------------------------------------------------------------
local function import_lines(buf)
	local out, started = {}, false
	for i = 0, api.nvim_buf_line_count(buf) - 1 do
		local line = api.nvim_buf_get_lines(buf, i, i + 1, false)[1]
		if line:match("^import%s") or line:match("^export%s+{%s*}") then
			started = true
			table.insert(out, line)
		elseif started then
			break
		end
	end
	return out
end

-----------------------------------------------------------------------
-- Crawler -------------------------------------------------------------
-----------------------------------------------------------------------
local function crawl(loc, depth, entry_root, acc, seen_txt, seen_name, import_set)
	if depth > M.opts.max_depth or not loc then
		return
	end
	local uri = loc.uri or loc.targetUri
	local range = loc.range or loc.targetSelectionRange
	if not (uri and range) then
		return
	end

	local buf = fn.bufadd(vim.uri_to_fname(uri))
	fn.bufload(buf)
	local root = ts.get_parser(buf, "tsx", {}):parse()[1]:root()
	local node = root:named_descendant_for_range(
		range.start.line,
		range.start.character,
		range["end"].line,
		range["end"].character
	)
	node = container(node) or node
	if not is_module_level(node) then
		return
	end
	if uri == vim.uri_from_bufnr(0) and ts_utils.is_parent(entry_root, node) then
		return
	end

	local snippet = node_text(node, buf)
	if #snippet >= M.opts.snippet_limit or seen_txt[snippet] then
		return
	end
	seen_txt[snippet] = true

	local header = string.format(
		"// -- %s:%d --",
		fn.fnamemodify(vim.uri_to_fname(uri), ":~:."):gsub("\\", "/"),
		range.start.line + 1
	)
	table.insert(acc, { depth = depth, header = header, text = snippet })

	for _, line in ipairs(import_lines(buf)) do
		import_set[line] = true
	end

	each_identifier(node, function(id)
		local name = node_text(id, buf)
		if seen_name[name] then
			return
		end
		seen_name[name] = true
		local row, col = id:start()
		crawl(
			best_definition(buf, { line = row, character = col }),
			depth + 1,
			entry_root,
			acc,
			seen_txt,
			seen_name,
			import_set
		)
	end)
end

-----------------------------------------------------------------------
-- Resolve entry symbol ------------------------------------------------
-----------------------------------------------------------------------
local function resolve_entry()
	local cur = ts_utils.get_node_at_cursor()
	if not cur then
		return
	end
	if cur:type() == "identifier" then
		local row, col = cur:start()
		local loc = best_definition(0, { line = row, character = col })
		if loc then
			local uri = loc.uri or loc.targetUri
			local buf = fn.bufadd(vim.uri_to_fname(uri))
			fn.bufload(buf)
			local root = ts.get_parser(buf, "tsx", {}):parse()[1]:root()
			local range = loc.range or loc.targetSelectionRange
			local node = root:named_descendant_for_range(
				range.start.line,
				range.start.character,
				range["end"].line,
				range["end"].character
			)
			return container(node) or node, buf
		end
	end
	return container(cur) or cur, 0
end

-----------------------------------------------------------------------
-- Main ----------------------------------------------------------------
-----------------------------------------------------------------------
function M.run()
	local entry_node, entry_buf = resolve_entry()
	if not entry_node then
		return vim.notify("Promptify: couldn’t resolve symbol", vim.log.levels.ERROR)
	end

	local acc, seen_txt, seen_name, import_set = {}, {}, {}, {}
	each_identifier(entry_node, function(id)
		local row, col = id:start()
		crawl(
			best_definition(entry_buf, { line = row, character = col }),
			1,
			entry_node,
			acc,
			seen_txt,
			seen_name,
			import_set
		)
	end)
	table.sort(acc, function(a, b)
		return a.depth < b.depth
	end)

	local lines = { "// ==== IMPORTS ====", "" }
	for imp, _ in pairs(import_set) do
		table.insert(lines, imp)
	end
	table.insert(lines, "")
	table.insert(lines, "// ==== DEPENDENCIES ====")
	for _, blk in ipairs(acc) do
		table.insert(lines, blk.header)
		vim.list_extend(lines, vim.split(blk.text, "\n", { plain = true }))
		table.insert(lines, "")
	end
	table.insert(lines, "// ==== ENTRY SYMBOL ====")
	vim.list_extend(lines, vim.split(node_text(entry_node, entry_buf), "\n", { plain = true }))

	local output = table.concat(lines, "\n")
	if #output > M.opts.prompt_limit then
		vim.notify("Promptify: slice exceeds prompt_limit (" .. #output .. " bytes)", vim.log.levels.WARN)
	end

	local out_buf = api.nvim_create_buf(false, true)
	api.nvim_buf_set_option(out_buf, "filetype", "typescript")
	api.nvim_buf_set_lines(out_buf, 0, -1, false, lines)
	api.nvim_set_current_buf(out_buf)
	pcall(fn.setreg, "+", output)
	vim.notify("Promptify: slice copied to clipboard", vim.log.levels.INFO)
end

return M
