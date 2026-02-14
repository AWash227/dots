return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  event = { "BufReadPost", "BufNewFile" },
  cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
  keys = {
    { "<c-space>", desc = "Increment selection" },
    { "<bs>", desc = "Decrement selection", mode = "x" },
  },
  opts = {
    ensure_installed = {
      "typescript",
      "tsx",
      "javascript",
      "json",
      "css",
      "html",
      "prisma",
      "lua",
      "python",
      "rust",
      "markdown",
      "markdown_inline",
    },
    auto_install = true,
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },
    indent = { enable = true },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "<C-space>",
        node_incremental = "<C-space>",
        scope_incremental = false,
        node_decremental = "<bs>",
      },
    },
  },
  config = function(_, opts)
    -- Register custom Prisma parser for Treesitter
    local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
    parser_config.prisma = {
      install_info = {
        url = "https://github.com/Binaryify/tree-sitter-prisma",
        files = { "src/parser.c" },
        branch = "main",
      },
      filetype = "prisma",
    }

    -- Set up prisma filetype
    vim.cmd([[ autocmd BufRead,BufNewFile *.prisma set filetype=prisma ]])

    require("nvim-treesitter.configs").setup(opts)
  end,
}
