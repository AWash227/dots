local M = {}

function M.symbol_under_cursor()
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
			local name = nil
			for child in node:iter_children() do
				if child:type():find("identifier") then
					name = vim.treesitter.query.get_node_text(child, bufnr)
					break
				end
			end
			name = name or type
			return { name = name, kind = "TS:" .. type }
		end
		node = node:parent()
	end
	return nil
end

return M
