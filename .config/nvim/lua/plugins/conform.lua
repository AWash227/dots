return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  opts = {
    format_on_save = {
      timeout_ms = 1000,
      lsp_format = "fallback",
    },
    formatters = {
      biome = {
        require_cwd = true,
      },
    },
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "black" },
      rust = { "rustfmt", lsp_format = "fallback" },
      typescript = { "biome", "prettier", stop_after_first = true },
      javascript = { "biome", "prettier", stop_after_first = true },
      typescriptreact = { "biome", "prettier", stop_after_first = true },
      javascriptreact = { "biome", "prettier", stop_after_first = true },
      json = { "biome", "prettier", stop_after_first = true },
      css = { "biome", "prettier", stop_after_first = true },
      html = { "biome", "prettier", stop_after_first = true },
    },
  },
}
