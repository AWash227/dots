return {
	"OXY2DEV/markview.nvim",
	lazy = false,
	ft = { "markdown" },
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons",
	},
	opts = {
		filetypes = { "markdown" },
		modes = { "n", "no", "c" },
		hybrid_modes = { "i" },
	},
}
