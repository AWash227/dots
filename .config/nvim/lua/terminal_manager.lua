local M = {}

local state = {
  terminals = {},
  current = 1,
  win = nil,
  last_editor_win = nil,
  height = 14,
  names = {},
}

local find_editor_win
local ensure_non_tree_anchor_win

local function is_valid_win(win)
  return win and vim.api.nvim_win_is_valid(win)
end

local function is_valid_buf(buf)
  return buf and vim.api.nvim_buf_is_valid(buf)
end

local function is_terminal_buf(buf)
  return is_valid_buf(buf) and vim.bo[buf].buftype == "terminal"
end

local function is_editor_win(win)
  if not is_valid_win(win) then
    return false
  end
  local buf = vim.api.nvim_win_get_buf(win)
  if not is_valid_buf(buf) then
    return false
  end
  return vim.bo[buf].buftype == "" and vim.bo[buf].filetype ~= "NvimTree"
end

local function refresh_terminals()
  local filtered = {}
  local names = {}
  for _, buf in ipairs(state.terminals) do
    if is_terminal_buf(buf) then
      table.insert(filtered, buf)
      names[buf] = state.names[buf]
    end
  end
  state.terminals = filtered
  state.names = names
  if #state.terminals == 0 then
    state.current = 1
    return
  end
  state.current = math.max(1, math.min(state.current, #state.terminals))
end

local function terminal_default_name(buf, idx)
  local title = vim.b[buf].term_title
  if title and title ~= "" then
    return title
  end
  return "terminal " .. tostring(idx)
end

local function terminal_name(buf, idx)
  return state.names[buf] or terminal_default_name(buf, idx)
end

local function shorten(text, max_len)
  if #text <= max_len then
    return text
  end
  return text:sub(1, max_len - 1) .. "…"
end

local function terminal_winbar()
  if #state.terminals == 0 then
    return " terminals (0)"
  end

  local parts = {}
  for i, buf in ipairs(state.terminals) do
    local marker = i == state.current and "*" or " "
    local name = shorten(terminal_name(buf, i), 16)
    parts[#parts + 1] = string.format("%s%d:%s", marker, i, name)
  end
  return string.format(" terminals (%d) active:%d | %s", #state.terminals, state.current, table.concat(parts, "  "))
end

local function refresh_terminal_winbar()
  if not is_valid_win(state.win) then
    return
  end
  vim.wo[state.win].winbar = terminal_winbar()
end

local function current_terminal_buf()
  refresh_terminals()
  return state.terminals[state.current]
end

local function ensure_bottom_terminal_window()
  if is_valid_win(state.win) then
    return state.win
  end

  local anchor_win = ensure_non_tree_anchor_win()
  if anchor_win then
    vim.api.nvim_set_current_win(anchor_win)
  end

  -- Split from non-NvimTree space so the tree pane is never vertically split.
  vim.cmd("botright split")
  vim.cmd("resize " .. tostring(state.height))
  state.win = vim.api.nvim_get_current_win()
  vim.wo.winfixheight = true
  return state.win
end

local function open_terminal_buf(buf)
  if not is_terminal_buf(buf) then
    return
  end
  local win = ensure_bottom_terminal_window()
  vim.api.nvim_set_current_win(win)
  vim.api.nvim_win_set_buf(win, buf)
  vim.cmd("resize " .. tostring(state.height))
  vim.wo.winfixheight = true
  refresh_terminal_winbar()
end

local function create_terminal_buf()
  ensure_bottom_terminal_window()
  vim.cmd("terminal")
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buflisted = false
  vim.bo[buf].bufhidden = "hide"
  table.insert(state.terminals, buf)
  state.current = #state.terminals
  state.names[buf] = terminal_default_name(buf, state.current)
  refresh_terminal_winbar()
  return buf
end

local function open_current_or_create()
  local buf = current_terminal_buf()
  if not is_terminal_buf(buf) then
    buf = create_terminal_buf()
  else
    open_terminal_buf(buf)
  end
  vim.cmd("startinsert")
end

find_editor_win = function()
  if is_editor_win(state.last_editor_win) then
    return state.last_editor_win
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if is_editor_win(win) then
      return win
    end
  end
  return nil
end

ensure_non_tree_anchor_win = function()
  local win = find_editor_win()
  if is_valid_win(win) then
    return win
  end

  -- Any non-tree window is a valid anchor.
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if is_valid_win(w) then
      local buf = vim.api.nvim_win_get_buf(w)
      if vim.bo[buf].filetype ~= "NvimTree" then
        return w
      end
    end
  end

  -- If only NvimTree exists, create right-hand non-tree space first.
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if is_valid_win(w) then
      local buf = vim.api.nvim_win_get_buf(w)
      if vim.bo[buf].filetype == "NvimTree" then
        vim.api.nvim_set_current_win(w)
        vim.cmd("rightbelow vsplit")
        return vim.api.nvim_get_current_win()
      end
    end
  end

  return nil
end

function M.toggle()
  if is_valid_win(state.win) then
    vim.api.nvim_win_close(state.win, true)
    state.win = nil
    return
  end
  open_current_or_create()
end

function M.new()
  create_terminal_buf()
  vim.cmd("startinsert")
end

function M.next()
  refresh_terminals()
  if #state.terminals == 0 then
    M.new()
    return
  end
  state.current = (state.current % #state.terminals) + 1
  open_current_or_create()
end

function M.prev()
  refresh_terminals()
  if #state.terminals == 0 then
    M.new()
    return
  end
  state.current = ((state.current - 2 + #state.terminals) % #state.terminals) + 1
  open_current_or_create()
end

function M.close_current()
  refresh_terminals()
  local buf = current_terminal_buf()
  if not is_terminal_buf(buf) then
    return
  end

  local replacement_idx = nil
  if #state.terminals > 1 then
    replacement_idx = state.current == #state.terminals and (state.current - 1) or (state.current + 1)
    local replacement_buf = state.terminals[replacement_idx]
    if is_valid_win(state.win) and is_terminal_buf(replacement_buf) then
      vim.api.nvim_win_set_buf(state.win, replacement_buf)
    end
  end

  local job = vim.b[buf].terminal_job_id
  if job and job > 0 then
    pcall(vim.fn.jobstop, job)
  end
  pcall(vim.api.nvim_buf_delete, buf, { force = true })

  refresh_terminals()
  if #state.terminals == 0 then
    if is_valid_win(state.win) then
      vim.api.nvim_win_close(state.win, true)
    end
    state.win = nil
    return
  end

  if replacement_idx then
    state.current = math.max(1, math.min(replacement_idx, #state.terminals))
  end

  if is_valid_win(state.win) then
    local next_buf = current_terminal_buf()
    if is_terminal_buf(next_buf) then
      vim.api.nvim_win_set_buf(state.win, next_buf)
      vim.api.nvim_set_current_win(state.win)
      vim.cmd("startinsert")
    end
  else
    open_current_or_create()
  end
  refresh_terminal_winbar()
end

function M.focus_terminal()
  if not is_valid_win(state.win) then
    open_current_or_create()
  end
  if is_valid_win(state.win) then
    vim.api.nvim_set_current_win(state.win)
    refresh_terminal_winbar()
    vim.cmd("startinsert")
  end
end

function M.focus_editor()
  local win = find_editor_win()
  if win then
    vim.api.nvim_set_current_win(win)
  end
end

function M.select()
  refresh_terminals()
  if #state.terminals == 0 then
    M.new()
    return
  end

  local items = {}
  for i, buf in ipairs(state.terminals) do
    items[#items + 1] = {
      idx = i,
      buf = buf,
      label = string.format("%d: %s", i, terminal_name(buf, i)),
    }
  end

  vim.ui.select(items, {
    prompt = "Select terminal",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if not choice then
      return
    end
    state.current = choice.idx
    open_current_or_create()
  end)
end

function M.jump(index)
  refresh_terminals()
  if #state.terminals == 0 then
    M.new()
    return
  end
  if index < 1 or index > #state.terminals then
    return
  end
  state.current = index
  open_current_or_create()
end

function M.rename_current()
  local buf = current_terminal_buf()
  if not is_terminal_buf(buf) then
    return
  end
  local idx = state.current
  local current_name = terminal_name(buf, idx)
  vim.ui.input({ prompt = "Terminal name: ", default = current_name }, function(input)
    if not input or input == "" then
      return
    end
    state.names[buf] = input
    refresh_terminal_winbar()
  end)
end

function M.help()
  local lines = {
    "Terminal Commands",
    "",
    "<leader>tt  Toggle terminal",
    "<leader>tn  New terminal",
    "<leader>t]  Next terminal",
    "<leader>t[  Prev terminal",
    "<leader>tl  List/select terminal",
    "<leader>tr  Rename current terminal",
    "<leader>tq  Close current terminal",
    "<leader>tf  Focus terminal",
    "<leader>te  Focus editor",
    "<leader>t1..9  Jump to terminal 1..9",
    "<leader>t?  Show this help",
    "",
    "In terminal: <Esc><Esc> -> normal mode",
  }
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "Terminal Manager" })
end

function M.setup(opts)
  opts = opts or {}
  state.height = opts.height or state.height

  vim.api.nvim_create_autocmd("WinEnter", {
    callback = function()
      local win = vim.api.nvim_get_current_win()
      local buf = vim.api.nvim_get_current_buf()
      if vim.bo[buf].buftype ~= "terminal" and vim.bo[buf].filetype ~= "NvimTree" then
        state.last_editor_win = win
      end
      if is_valid_win(state.win) and win == state.win then
        vim.wo.winfixheight = true
        refresh_terminal_winbar()
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "TermOpen", "TermClose", "BufEnter" }, {
    callback = function(args)
      if is_terminal_buf(args.buf) then
        refresh_terminals()
        if not state.names[args.buf] then
          for i, buf in ipairs(state.terminals) do
            if buf == args.buf then
              state.names[buf] = terminal_default_name(buf, i)
              break
            end
          end
        end
        refresh_terminal_winbar()
      end
    end,
  })

  vim.keymap.set("n", "<leader>tt", function()
    M.toggle()
  end, { desc = "Terminal Toggle" })

  vim.keymap.set("n", "<leader>tn", function()
    M.new()
  end, { desc = "Terminal New" })

  vim.keymap.set("n", "<leader>t]", function()
    M.next()
  end, { desc = "Terminal Next" })

  vim.keymap.set("n", "<leader>t[", function()
    M.prev()
  end, { desc = "Terminal Prev" })

  vim.keymap.set("n", "<leader>tq", function()
    M.close_current()
  end, { desc = "Terminal Close" })

  vim.keymap.set("n", "<leader>tl", function()
    M.select()
  end, { desc = "Terminal List" })

  vim.keymap.set("n", "<leader>tr", function()
    M.rename_current()
  end, { desc = "Terminal Rename" })

  vim.keymap.set("n", "<leader>t?", function()
    M.help()
  end, { desc = "Terminal Help" })

  vim.keymap.set("n", "<leader>tf", function()
    M.focus_terminal()
  end, { desc = "Terminal Focus" })

  vim.keymap.set("n", "<leader>te", function()
    M.focus_editor()
  end, { desc = "Editor Focus" })

  vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], { desc = "Terminal Normal Mode" })

  for i = 1, 9 do
    vim.keymap.set("n", "<leader>t" .. tostring(i), function()
      M.jump(i)
    end, { desc = "Terminal " .. tostring(i) })
  end
end

return M
