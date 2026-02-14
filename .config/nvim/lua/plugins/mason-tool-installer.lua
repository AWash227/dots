return {
  "WhoIsSethDaniel/mason-tool-installer.nvim",
  dependencies = {
    "williamboman/mason.nvim",
  },
  opts = {
    ensure_installed = {
      "prettier",
      "biome",
      "eslint_d",
      "stylua",
      "black",
      "rustfmt",
    },
    run_on_start = true,
    start_delay = 3000,
    debounce_hours = 24,
  },
}
