-- lua/context/commands.lua
--
-- Collect *only* the files a symbol depends on (outgoing edges).

local core = require("context.core")
local graph = require("context.graph")

local function symbol_under_cursor()
	local bufnr, uri = 0, vim.uri_from_bufnr(0)
	local params = { textDocument = { uri = uri } }
	local replies = vim.lsp.buf_request_sync(bufnr, "textDocument/documentSymbol", params, core.cfg.lsp_timeout)
	if replies then
		local row, col = unpack(vim.api.nvim_win_get_cursor(0))
		for _, resp in pairs(replies) do
			local syms = resp.result
			local function find(tbl)
				for _, s in ipairs(tbl) do
					local r = s.range or s.location.range
					local sr = r.start.line + 1
					local er = r["end"].line + 1
					if row >= sr and row <= er then
						if s.children then
							local c = find(s.children)
							if c then
								return c
							end
						end
						return s
					end
				end
			end
			local hit = syms and find(syms)
			if hit then
				return hit.name or hit.detail, vim.api.nvim_buf_get_name(0)
			end
		end
	end
	return vim.fn.expand("<cword>"), vim.api.nvim_buf_get_name(0)
end

local function outgoing_files(dep_graph, root_key)
	local q, seen, files = { root_key }, {}, {}
	while #q > 0 do
		local k = table.remove(q, 1)
		if not seen[k] and dep_graph.nodes[k] then
			seen[k] = true
			local node = dep_graph.nodes[k]
			if not core.skip(node.file) then
				files[node.file] = true
			end
			for _, e in ipairs(dep_graph.edges or {}) do
				if e.from == k and (e.type == "calls" or e.type == "imports") then
					q[#q + 1] = e.to
				end
			end
		end
	end
	local list = {}
	for f in pairs(files) do
		list[#list + 1] = f
	end
	table.sort(list)
	return list
end

vim.api.nvim_create_user_command("ExtractContext", function(opts)
	local depth = tonumber(opts.args) or core.cfg.depth
	local sym, root_f = symbol_under_cursor()
	local root_key = ("%s::%s"):format(root_f, sym)

	vim.notify(("⟳ building outgoing dependency graph (depth %d)…"):format(depth))

	graph.build_dependency_graph(depth, function(dg)
		if not dg or not dg.nodes then
			vim.notify("[Context] graph failed", vim.log.levels.ERROR)
			return
		end

		local files = outgoing_files(dg, root_key)
		if #files == 0 then
			vim.notify("[Context] no dependent files", vim.log.levels.WARN)
			return
		end

		local out = { ("[Context] Files needed for %s (depth %d):"):format(sym, depth) }
		for _, path in ipairs(files) do
			local bufnr = core.load_buf(path)
			if bufnr then
				local total = vim.api.nvim_buf_line_count(bufnr)
				local cap = math.min(total, core.cfg.max_lines)
				out[#out + 1] = ("── %s (first %d/%d lines) ──"):format(path, cap, total)
				vim.list_extend(out, vim.api.nvim_buf_get_lines(bufnr, 0, cap, false))
				out[#out + 1] = ""
			else
				out[#out + 1] = ("[skip] %s"):format(path)
			end
		end
		vim.notify(table.concat(out, "\n"), vim.log.levels.INFO)
	end)
end, {
	desc = "Outgoing-dependency files for symbol under cursor",
	nargs = "?",
	complete = function()
		return { "1", "2", "3", "4", "5" }
	end,
})
