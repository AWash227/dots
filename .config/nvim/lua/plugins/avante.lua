return {
	{
		"yetone/avante.nvim",
		event = "VeryLazy",
		lazy = false,
		version = false, -- never set to "*", pull latest
		opts = {
			provider = "ollama",
			providers = {
				ollama = {
					endpoint = "http://127.0.0.1:11434",
					model = "gpt-oss:20b",
					-- Required: tells avante how to check if the provider is available
					is_env_set = function()
						-- Check if Ollama is running
						local ok = pcall(function()
							vim.fn.system("curl -s http://127.0.0.1:11434")
						end)
						return true -- return true to enable; avante will error on actual failure
					end,
				},
			},
			-- Keybindings (defaults, listed for reference)
			mappings = {
				ask = "<leader>aa", -- open chat sidebar
				edit = "<leader>ae", -- edit selected code
				refresh = "<leader>ar", -- refresh response
			},
		},
		build = "make",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-tree/nvim-web-devicons",
			{
				"OXY2DEV/markview.nvim",
				opts = {
					filetypes = { "markdown", "Avante" },
				},
				ft = { "markdown", "Avante" },
			},
		},
	},
}
