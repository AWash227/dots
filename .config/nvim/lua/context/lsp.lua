-- lua/context/lsp.lua

local M = {}

-- Return the first active LSP client for the current buffer, or nil
function M.get_active_client()
	local bufnr = vim.api.nvim_get_current_buf()
	local clients = vim.lsp.get_clients({ bufnr = bufnr })
	return #clients > 0 and clients[1] or nil
end

-- Return LSP position params for current cursor, including encoding
function M.get_position_params()
	local client = M.get_active_client()
	if not client then
		return nil
	end
	local encoding = client.offset_encoding or "utf-16"
	return vim.lsp.util.make_position_params(0, encoding)
end

-- Recursively find the smallest symbol containing (row, col)
function M.find_symbol_at_position(symbols, row, col)
	for _, sym in ipairs(symbols) do
		if sym.range then
			local srow, scol = sym.range.start.line + 1, sym.range.start.character + 1
			local erow, ecol = sym.range["end"].line + 1, sym.range["end"].character + 1
			local inside = (row > srow or (row == srow and col >= scol))
				and (row < erow or (row == erow and col <= ecol))
			if inside then
				if sym.children then
					local child = M.find_symbol_at_position(sym.children, row, col)
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

-- Request all references for the symbol at given params, callback receives table of refs
function M.references_for_symbol(params, cb)
	local client = M.get_active_client()
	if not client then
		vim.notify("[Context] No active LSP client found.", vim.log.levels.WARN)
		cb(nil)
		return
	end
	params.context = { includeDeclaration = true }
	client.request("textDocument/references", params, function(err, result)
		if err then
			vim.notify("[Context] Failed to fetch references: " .. tostring(err.message or err), vim.log.levels.ERROR)
			cb(nil)
			return
		end
		cb(result or {})
	end, vim.api.nvim_get_current_buf())
end

-- Convert LSP URI to file path
function M.uri_to_path(uri)
	return vim.uri_to_fname(uri)
end

return M
