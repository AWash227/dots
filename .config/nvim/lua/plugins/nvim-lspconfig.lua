return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "williamboman/mason-lspconfig.nvim",
    "b0o/schemastore.nvim",
  },
  config = function()
    local has_cmp_nvim_lsp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
    local capabilities = has_cmp_nvim_lsp and cmp_nvim_lsp.default_capabilities()
      or vim.lsp.protocol.make_client_capabilities()
    local enabled_servers = {
      "cssls",
      "html",
      "jsonls",
      "rust_analyzer",
      "pyright",
      "prismals",
    }

    vim.lsp.config("tailwindcss", {
      capabilities = capabilities,
      filetypes = {
        "html",
        "css",
        "scss",
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
      },
    })
    if vim.fn.executable("tailwindcss-language-server") == 1 then
      table.insert(enabled_servers, "tailwindcss")
    end

    vim.lsp.config("cssls", { capabilities = capabilities })
    vim.lsp.config("html", { capabilities = capabilities })

    local has_schemastore, schemastore = pcall(require, "schemastore")
    vim.lsp.config("jsonls", {
      capabilities = capabilities,
      settings = {
        json = {
          schemas = has_schemastore and schemastore.json.schemas() or {},
          validate = { enable = true },
        },
      },
    })

    vim.lsp.config("eslint", {
      capabilities = capabilities,
      settings = {
        workingDirectory = { mode = "auto" },
      },
      on_attach = function(_, bufnr)
        local group = vim.api.nvim_create_augroup("LspEslintFixAll", { clear = false })
        vim.api.nvim_clear_autocmds({ group = group, buffer = bufnr })
        vim.api.nvim_create_autocmd("BufWritePre", {
          group = group,
          buffer = bufnr,
          callback = function()
            if vim.fn.exists(":LspEslintFixAll") == 2 then
              vim.cmd("silent! LspEslintFixAll")
            end
          end,
        })
      end,
    })
    if vim.fn.executable("vscode-eslint-language-server") == 1 then
      table.insert(enabled_servers, "eslint")
    end

    vim.lsp.config("biome", {
      capabilities = capabilities,
    })
    if vim.fn.executable("biome") == 1 then
      table.insert(enabled_servers, "biome")
    end

    vim.lsp.config("rust_analyzer", { capabilities = capabilities })
    vim.lsp.config("pyright", { capabilities = capabilities })
    vim.lsp.config("prismals", { capabilities = capabilities })

    vim.lsp.enable(enabled_servers)
  end,
}
