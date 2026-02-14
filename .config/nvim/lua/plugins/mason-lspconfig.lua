return {
  "williamboman/mason-lspconfig.nvim",
  opts = {
    ensure_installed = {
      "biome",
      "eslint",
      "jsonls",
      "tailwindcss",
      "cssls",
      "html",
      "lua_ls",
      "pyright",
      "rust_analyzer",
      "prismals",
      "ts_ls",
    },
    automatic_enable = false,
  },
}
