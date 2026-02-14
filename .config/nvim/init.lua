-- ===============================
--   Neovim Lua Config (init.lua)
-- ===============================
local function ensure_node_toolchain_in_path()
  if vim.fn.executable("node") == 1 and vim.fn.executable("npm") == 1 then
    return
  end

  local nvm_bins = vim.fn.glob(vim.fn.expand("~/.nvm/versions/node/*/bin"), false, true)
  table.sort(nvm_bins)

  for i = #nvm_bins, 1, -1 do
    local bin = nvm_bins[i]
    if vim.fn.executable(bin .. "/node") == 1 then
      vim.env.PATH = bin .. ":" .. vim.env.PATH
      return
    end
  end
end

ensure_node_toolchain_in_path()

-- Lazy, Mason, Mason-LSP setup
require("config.lazy")
require("terminal_manager").setup({
  height = 14,
})

-- All plugin configs are now in lua/plugins/ with lazy loading

-- ===============================
--         LSP Config
-- ===============================
-- LSP servers are now configured in lua/plugins/nvim-lspconfig.lua
vim.opt.termguicolors = true

-- ===============================
--        Formatter Config
-- ===============================
-- Formatter config is now in lua/plugins/conform.lua

-- ===============================
--      nvim-cmp Completion
-- ===============================
-- Completion config is now in lua/plugins/nvim-cmp.lua

-- ===============================
--      Keymaps & UI Settings
-- ===============================
vim.cmd("colorscheme github_dark_colorblind")

-- Most keymaps are now in their respective plugin files
vim.keymap.set("n", "<leader>r", "<cmd>lua vim.lsp.buf.rename()<CR>", { desc = "Rename Symbol" })
vim.keymap.set("n", "<leader>do", "<cmd>lua vim.diagnostic.open_float()<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", { desc = "Go to Definition" })
vim.keymap.set("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", { desc = "Find References" })
vim.keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", { desc = "Hover Documentation" })

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.softtabstop = 2
vim.opt.equalalways = false

vim.opt.backupcopy = "yes"
-- Formatting is handled by conform.nvim with format_on_save
vim.keymap.set({ "i" }, "<C-k>", function()
	require("luasnip").expand_or_jump()
end, { silent = true })
vim.keymap.set({ "i" }, "<C-j>", function()
	require("luasnip").jump(-1)
end, { silent = true })
