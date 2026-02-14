-- lua/context/graph.lua
--
-- Build *outgoing-dependency* graph for the symbol under cursor.
--   • Outgoing call-hierarchy edges  →  type = "call_outgoing"
--   • Reference edges (declarations we jump to) → type = "reference"
--   • NO incoming callers are recorded.

local lsp = require("context.lsp")

local M = {}

local function key(path, name)
	return ("%s::%s"):format(path, name)
end

-- callback(graph) on_done
function M.build_dependency_graph(depth_limit, on_done)
	depth_limit = depth_limit or 3

	local g = { nodes = {}, edges = {}, visited = {} }
	local q, pending = {}, 0

	local function enqueue(n)
		local k = key(n.file, n.symbol)
		if not g.visited[k] and n.depth <= depth_limit then
			g.visited[k] = true
			q[#q + 1] = n
		end
	end

	local function maybe_finish()
		if pending == 0 and #q == 0 then
			on_done(g)
		end
	end

	----------------------------------------------------------------
	-- 1. find symbol under cursor
	----------------------------------------------------------------
	local params = lsp.get_position_params()
	if not params then
		vim.notify("[Context] No LSP params", vim.log.levels.ERROR)
		on_done(nil)
		return
	end
	local client = lsp.get_active_client()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local start_file = vim.api.nvim_buf_get_name(0)

	client.request("textDocument/documentSymbol", { textDocument = params.textDocument }, function(_, syms)
		local sym = syms and lsp.find_symbol_at_position(syms, row, col + 1)
		if not sym or not sym.name then
			vim.notify("[Context] Could not resolve symbol", vim.log.levels.ERROR)
			on_done(nil)
			return
		end

		enqueue({ file = start_file, symbol = sym.name, depth = 0, line = row - 1, character = col })

		----------------------------------------------------------------
		-- 2. BFS, outgoing-only
		----------------------------------------------------------------
		local function step()
			if #q == 0 then
				maybe_finish()
				return
			end
			local n = table.remove(q, 1)
			local k = key(n.file, n.symbol)

			if not g.nodes[k] then
				g.nodes[k] = { file = n.file, symbol = n.symbol }
			end
			if n.depth >= depth_limit then
				vim.schedule(step)
				return
			end

			local bufnr = vim.fn.bufnr(n.file, true)
			local pos_params = {
				textDocument = { uri = vim.uri_from_fname(n.file) },
				position = { line = n.line, character = n.character },
			}

			-- ---- Call hierarchy (outgoing only)
			pending = pending + 1
			client.request("textDocument/prepareCallHierarchy", pos_params, function(_, items)
				pending = pending - 1
				local i = items and items[1]
				if i then
					pending = pending + 1
					client.request("callHierarchy/outgoingCalls", { item = i }, function(_, calls)
						pending = pending - 1
						if calls then
							for _, c in ipairs(calls) do
								local tgt = c.to
								local tgt_path = lsp.uri_to_path(tgt.uri)
								local tgt_key = key(tgt_path, tgt.name)
								table.insert(g.edges, { from = k, to = tgt_key, type = "call_outgoing" })
								enqueue({
									file = tgt_path,
									symbol = tgt.name,
									depth = n.depth + 1,
									line = tgt.range.start.line,
									character = tgt.range.start.character,
								})
							end
						end
						vim.schedule(step)
						maybe_finish()
					end)
				else
					-- ---- Reference fallback (includeDeclaration = true)
					local ref_params = {
						textDocument = { uri = vim.uri_from_fname(n.file) },
						position = { line = n.line, character = n.character },
						context = { includeDeclaration = true },
					}
					pending = pending + 1
					lsp.references_for_symbol(ref_params, function(refs)
						pending = pending - 1
						if refs then
							for _, ref in ipairs(refs) do
								local tgt_path = lsp.uri_to_path(ref.uri)
								local tgt_pos = ref.range.start
								local tgt_bufnr = vim.fn.bufnr(tgt_path, true)
								vim.api.nvim_buf_call(tgt_bufnr, function()
									local c2 = lsp.get_active_client()
									if not c2 then
										return
									end
									c2.request(
										"textDocument/documentSymbol",
										{ textDocument = { uri = ref.uri } },
										function(_, syms2)
											local s2 = syms2
												and lsp.find_symbol_at_position(
													syms2,
													tgt_pos.line + 1,
													tgt_pos.character + 1
												)
											local tgt_name = s2 and s2.name or "UNKNOWN"
											local tgt_key = key(tgt_path, tgt_name)
											table.insert(g.edges, { from = k, to = tgt_key, type = "reference" })
											enqueue({
												file = tgt_path,
												symbol = tgt_name,
												depth = n.depth + 1,
												line = tgt_pos.line,
												character = tgt_pos.character,
											})
										end,
										tgt_bufnr
									)
								end)
							end
						end
						vim.schedule(step)
						maybe_finish()
					end)
				end
			end, bufnr)
		end

		step() -- kick off BFS
	end)
end

return M
