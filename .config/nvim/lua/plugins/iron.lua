return {
	"Vigemus/iron.nvim",
	config = function()
		local iron = require("iron.core")
		local view = require("iron.view")

		iron.setup({
			config = {
				scratch_repl = true,
				repl_definition = {
					python = {
						command = { "ipython", "-i" },
						format = require("iron.fts.common").bracketed_paste,
					},
				},
				repl_open_cmd = view.split.vertical.botright("40%"),
			},
			keymaps = {
				send_line = "<S-CR>",
				visual_send = "<S-CR>",
				send_file = "<C-CR>",
				interrupt = "<leader>i",
				clear = "<leader>c",
				exit = "<leader>q",
			},
			highlight = { italic = true },
			ignore_blank_lines = true,
		})

		-- Auto-start REPL on Python file
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "python",
			callback = function()
				vim.cmd("IronRepl")
			end,
		})

		-- Auto-inject show_plot function after REPL starts
		vim.api.nvim_create_autocmd("User", {
			pattern = "IronReplOpen",
			callback = function()
				local lines = {
					"import matplotlib.pyplot as plt",
					"import os",
					"def show_plot():",
					"    plt.savefig('/tmp/plot.png', dpi=150)",
					"    os.system('kitty +kitten icat /tmp/plot.png')",
					"plt.show = show_plot",
				}
				for _, line in ipairs(lines) do
					vim.fn["iron#send"]("python", line .. "\\n")
				end
			end,
		})
	end,
	keys = {
		{ "<S-CR>", mode = { "n", "v" }, desc = "Run line or selection (Shift+Enter)" },
		{ "<C-CR>", desc = "Run entire file (Ctrl+Enter)" },
		{ "<leader>i", desc = "Interrupt REPL" },
		{ "<leader>c", desc = "Clear REPL" },
		{ "<leader>q", desc = "Quit REPL" },
	},
}
