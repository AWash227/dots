return {
	"dmmulroy/tsc.nvim",
	cmd = { "TSC", "TSCOpen", "TSCClose", "TSCStop" },
	dependencies = { "nvim-lua/plenary.nvim", "rcarriga/nvim-notify" }, -- notify is optional
	opts = {
		-- Keep tsc available, but avoid duplicate live diagnostics with LSP/eslint.
		run_as_monorepo = true,
		flags = { watch = true, noEmit = true },

		auto_start_watch_mode = false,
		use_diagnostics = false,
		auto_open_qflist = false,
		auto_close_qflist = true,
	},
}
