return {
	"L3MON4D3/LuaSnip",
	build = "make install_jsregexp",
	event = "InsertEnter",
	dependencies = {
		"rafamadriz/friendly-snippets",
	},
	config = function()
		require("luasnip.loaders.from_lua").lazy_load({ paths = "~/.config/nvim/lua/snippets" })
		require("luasnip.loaders.from_vscode").lazy_load()
	end,
}
