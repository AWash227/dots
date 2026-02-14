-- lua/context/core.lua

local M = {}

local function get_active_client()
	local bufnr = vim.api.nvim_get_current_buf()
	local clients = vim.lsp.get_clients({ bufnr = bufnr })
	return #clients > 0 and clients[1] or nil
end

local function find_symbol_at_position(symbols, row, col)
	for _, sym in ipairs(symbols) do
		if sym.range then
			local srow, scol = sym.range.start.line + 1, sym.range.start.character + 1
			local erow, ecol = sym.range["end"].line + 1, sym.range["end"].character + 1
			local inside = (row > srow or (row == srow and col >= scol))
				and (row < erow or (row == erow and col <= ecol))
			if inside then
				if sym.children then
					local child = find_symbol_at_position(sym.children, row, col)
					if child then
						return child
					end
				end
				return sym
			end
		end
	end
	return nil
end

-- Fallback: Tree-sitter based symbol under cursor
local function ts_symbol_under_cursor()
	local ts = vim.treesitter
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row, col = cursor[1] - 1, cursor[2]

	local ok, parser = pcall(ts.get_parser, bufnr)
	if not ok or not parser then
		vim.notify("[Context] No Tree-sitter parser found for this buffer.", vim.log.levels.WARN)
		return nil
	end

	local root = parser:parse()[1]:root()
	local node = root:named_descendant_for_range(row, col, row, col)

	-- Walk up to interesting nodes (e.g. function, method, variable, class)
	while node do
		local type = node:type()
		if
			type == "function_declaration"
			or type == "method_definition"
			or type == "variable_declaration"
			or type == "lexical_declaration"
			or type == "class_declaration"
			or type == "arrow_function"
			or type == "function"
		then
			-- For display, get first child identifier if possible
			local name = nil
			for child in node:iter_children() do
				if child:type():find("identifier") then
					name = vim.treesitter.query.get_node_text(child, bufnr)
					break
				end
			end
			-- Fallback to node type as name
			name = name or type
			return { name = name, kind = "TS:" .. type }
		end
		node = node:parent()
	end
	return nil
end

function M.get_symbol_under_cursor()
	local client = get_active_client()
	local bufnr = vim.api.nvim_get_current_buf()
	local encoding = client and (client.offset_encoding or "utf-16") or "utf-16"
	local params = vim.lsp.util.make_position_params(0, encoding)

	if client then
		client.request("textDocument/documentSymbol", { textDocument = params.textDocument }, function(_, result)
			local cursor = vim.api.nvim_win_get_cursor(0)
			local row, col = cursor[1], cursor[2] + 1
			local symbol = result and find_symbol_at_position(result, row, col)
			if symbol then
				vim.notify(string.format("[Context] LSP: %s (%s)", symbol.name, symbol.kind), vim.log.levels.INFO)
			else
				-- Fallback: try Tree-sitter
				local ts_sym = ts_symbol_under_cursor()
				if ts_sym then
					vim.notify(
						string.format("[Context] Tree-sitter: %s (%s)", ts_sym.name, ts_sym.kind),
						vim.log.levels.INFO
					)
				else
					vim.notify("[Context] No symbol found under cursor (LSP+TS).", vim.log.levels.WARN)
				end
			end
		end, bufnr)
	else
		-- LSP not available, use Tree-sitter only
		local ts_sym = ts_symbol_under_cursor()
		if ts_sym then
			vim.notify(string.format("[Context] Tree-sitter: %s (%s)", ts_sym.name, ts_sym.kind), vim.log.levels.INFO)
		else
			vim.notify("[Context] No symbol found under cursor (TS-only).", vim.log.levels.WARN)
		end
	end
end

function M.setup()
	vim.api.nvim_create_user_command("ExtractContext", M.get_symbol_under_cursor, {
		desc = "Extract symbol under cursor using LSP/Tree-sitter",
	})
end

-- Plugin-wide defaults (override from user config later if desired)
M.cfg = {
	depth = 3, -- BFS depth for dependency graph
	skip_patterns = { "node_modules", "%.d%.ts$" },
	max_lines = 800, -- cap huge file dumps
	lsp_timeout = 800, -- ms for sync LSP calls
}

--------------------------------------------------------------------- utilities
function M.skip(path)
	for _, pat in ipairs(M.cfg.skip_patterns) do
		if path:find(pat) then
			return true
		end
	end
end

function M.load_buf(path)
	local ok, bufnr = pcall(vim.fn.bufnr, path, true)
	if not ok or bufnr < 1 then
		return nil
	end
	if not vim.api.nvim_buf_is_loaded(bufnr) then
		if not pcall(vim.fn.bufload, bufnr) then
			return nil
		end -- swapfile busy
	end
	return bufnr
end

return M
