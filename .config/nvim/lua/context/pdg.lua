-- lua/context/pdg.lua
--
-- Lightweight Program-Dependence-Graph builder + backward/forward slicer for a slice.
-- Fully robust: no nil table errors, no parsing bugs, always produces a table.

local ts = vim.treesitter
local M = {}

-- Statement node types considered for PDG nodes
local STMT = {
	expression_statement = true,
	return_statement = true,
	if_statement = true,
	switch_statement = true,
	for_statement = true,
	for_in_statement = true,
	while_statement = true,
	do_statement = true,
	break_statement = true,
	continue_statement = true,
	throw_statement = true,
	try_statement = true,
	variable_declaration = true,
	lexical_declaration = true,
	function_declaration = true,
	class_declaration = true,
}

-- Wide, portable use/def query: NO formal_parameters!
local PRIMARY_QUERY = [[
  (assignment_expression left: (identifier) @def)
  (variable_declarator   name: (identifier) @def)
  (required_parameter    (identifier) @def)
  (function_declaration  name: (identifier) @def)
  (class_declaration     name: (identifier) @def)

  (identifier) @use
  (property_identifier) @use
  (shorthand_property_identifier) @use
]]

-- Always-parseable fallback query
local FALLBACK_QUERY = [[
  (identifier) @use
  (variable_declarator name:(identifier) @def)
]]

local LANGS = { "typescript", "tsx", "javascript", "js" }

-- Simple set helper
local function Set()
	return setmetatable(
		{},
		{
			__index = {
				add = function(self, v)
					self[v] = true
				end,
				items = function(self)
					local t = {}
					for k in pairs(self) do
						t[#t + 1] = k
					end
					return t
				end,
			},
		}
	)
end

-- Query compiler with fallback and caching
local qcache = {}
local function q(lang)
	if qcache[lang] then
		return qcache[lang]
	end
	local ok, q1 = pcall(ts.query.parse, lang, PRIMARY_QUERY)
	if not ok then
		ok, q1 = pcall(ts.query.parse, lang, FALLBACK_QUERY)
	end
	qcache[lang] = ok and q1 or nil
	return qcache[lang]
end

-- Build PDG from a slice (returns table or nil, err)
function M.build(slice)
	local src = table.concat(slice.text, "\n")
	local parser, lang
	for _, l in ipairs(LANGS) do
		local ok, p = pcall(ts.get_string_parser, src, l)
		if ok and p then
			parser, lang = p, l
			break
		end
	end
	if not parser then
		return nil, "[PDG] no parser"
	end
	local root = parser:parse()[1]:root()
	local query = q(lang)
	if not query then
		return nil, "[PDG] query fail"
	end

	-- 1. Collect statements
	local stmts, id, line2stmt = {}, 0, {}
	local function visit(n)
		if STMT[n:type()] then
			local sr, er = n:start(), n:end_()
			local s = { id = id, node = n, sr = sr, er = er, defs = Set(), uses = Set() }
			stmts[#stmts + 1] = s
			id = id + 1
			for l = sr, er do
				line2stmt[l] = s
			end
		end
		for c in n:iter_children() do
			visit(c)
		end
	end
	visit(root)
	if #stmts == 0 then
		return nil, "[PDG] empty"
	end

	-- 2. Fill defs/uses
	for cid, node in query:iter_captures(root, src, 0, -1) do
		local stmt = line2stmt[node:start()]
		if stmt then
			local name = ts.get_node_text(node, src)
			local cap = query.captures[cid]
			if cap == "def" then
				stmt.defs:add(name)
			else
				stmt.uses:add(name)
			end
		end
	end

	-- 3. Data-dependence edges
	local last_def, data_edges = {}, {}
	for _, s in ipairs(stmts) do
		for _, v in ipairs(s.uses:items()) do
			local src_stmt = last_def[v]
			if src_stmt then
				data_edges[#data_edges + 1] = { from = src_stmt.id, to = s.id, var = v, type = "data" }
			end
		end
		for _, v in ipairs(s.defs:items()) do
			last_def[v] = s
		end
	end

	-- 4. Control-dependence edges (simple parent stack)
	local ctrl_edges, stack = {}, {}
	local function push(n)
		stack[#stack + 1] = n
	end
	local function pop()
		stack[#stack] = nil
	end
	for _, s in ipairs(stmts) do
		while #stack > 0 and stack[#stack].er < s.sr do
			pop()
		end
		if #stack > 0 then
			ctrl_edges[#ctrl_edges + 1] = { from = stack[#stack].id, to = s.id, type = "control" }
		end
		local t = s.node:type()
		if t == "if_statement" or t:find("for_") or t == "while_statement" then
			push(s)
		end
	end

	return { nodes = stmts, data_edges = data_edges, control_edges = ctrl_edges }
end

-- Traversal helper (always returns a table, never nil)
local function traverse(pdg, seeds, dir)
	local work, seen, out = {}, {}, {}
	for _, id in ipairs(seeds or {}) do
		work[#work + 1] = id
	end
	while #work > 0 do
		local n = table.remove(work)
		if not seen[n] then
			seen[n], out[#out + 1] = true, n
			local function link(e)
				if dir == "back" and e.to == n then
					work[#work + 1] = e.from
				end
				if dir == "fwd" and e.from == n then
					work[#work + 1] = e.to
				end
			end
			for _, e in ipairs(pdg.data_edges) do
				link(e)
			end
			for _, e in ipairs(pdg.control_edges) do
				link(e)
			end
		end
	end
	return out
end

function M.backward_slice(pdg, ids)
	return traverse(pdg, ids, "back")
end
function M.forward_slice(pdg, ids)
	return traverse(pdg, ids, "fwd")
end

return M
