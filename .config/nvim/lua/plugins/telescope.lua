return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.8',
  cmd = "Telescope",
  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
    { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
    { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
    { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
    { "<leader>dd", "<cmd>Telescope diagnostics bufnr=0<cr>", desc = "Buffer Diagnostics" },
    { "<leader>dD", "<cmd>Telescope diagnostics<cr>", desc = "Workspace Diagnostics" },
  },
  dependencies = {
    'nvim-lua/plenary.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make',
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },
  },
  config = function()
    require('telescope').setup({
      defaults = {
        file_ignore_patterns = { "node_modules", ".git/", ".next/", "dist/", "build/" },
        layout_config = {
          horizontal = {
            preview_width = 0.55,
          },
        },
      },
    })
    pcall(require('telescope').load_extension, 'fzf')
  end,
}
