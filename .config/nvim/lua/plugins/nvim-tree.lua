return {
	"nvim-tree/nvim-tree.lua",
	keys = {
		{ "\\", "<cmd>NvimTreeToggle<cr>", desc = "Toggle NvimTree" },
		{ "<leader>e", "<cmd>NvimTreeFindFile<cr>", desc = "Find current file in tree" },
	},
	init = function()
		-- Disable netrw before nvim-tree loads
		vim.g.loaded_netrw = 1
		vim.g.loaded_netrwPlugin = 1
	end,
	config = function()
		local function styled_from(group, style)
			local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
			for k, v in pairs(style) do
				hl[k] = v
			end
			return hl
		end

		local function apply_tree_highlights()
			-- Quiet structure scaffolding.
			vim.api.nvim_set_hl(0, "NvimTreeIndentMarker", { link = "Comment" })
			vim.api.nvim_set_hl(0, "NvimTreeFolderArrowClosed", { link = "Comment" })
			vim.api.nvim_set_hl(0, "NvimTreeFolderArrowOpen", { link = "Comment" })

			-- Folder names should carry hierarchy by weight, not color.
			vim.api.nvim_set_hl(0, "NvimTreeFolderName", styled_from("NvimTreeFolderName", { bold = true }))
			vim.api.nvim_set_hl(0, "NvimTreeOpenedFolderName", styled_from("NvimTreeOpenedFolderName", { bold = true }))
			vim.api.nvim_set_hl(0, "NvimTreeEmptyFolderName", styled_from("NvimTreeEmptyFolderName", { bold = true }))
			vim.api.nvim_set_hl(0, "NvimTreeRootFolder", styled_from("NvimTreeRootFolder", { bold = true }))

			-- Dotfiles/special metadata should recede.
			vim.api.nvim_set_hl(0, "NvimTreeDotfile", { link = "Comment" })
			vim.api.nvim_set_hl(0, "NvimTreeHiddenFileHL", { link = "Comment" })
			vim.api.nvim_set_hl(0, "NvimTreeHiddenFolderHL", { link = "Comment" })
			vim.api.nvim_set_hl(0, "NvimTreeSpecialFile", styled_from("Comment", { italic = true }))

			-- Git state should inform quietly.
			vim.api.nvim_set_hl(0, "NvimTreeGitDirty", { link = "Comment" })
			vim.api.nvim_set_hl(0, "NvimTreeGitNew", { link = "Comment" })
			vim.api.nvim_set_hl(0, "NvimTreeGitDeleted", { link = "Comment" })
			vim.api.nvim_set_hl(0, "NvimTreeGitDirtyIcon", { link = "Comment" })
			vim.api.nvim_set_hl(0, "NvimTreeGitNewIcon", { link = "Comment" })
			vim.api.nvim_set_hl(0, "NvimTreeGitDeletedIcon", { link = "Comment" })
			vim.api.nvim_set_hl(0, "NvimTreeGitRenamedIcon", { link = "Comment" })
			vim.api.nvim_set_hl(0, "NvimTreeGitStagedIcon", { link = "Comment" })
			vim.api.nvim_set_hl(0, "NvimTreeGitMergeIcon", { link = "Comment" })
			vim.api.nvim_set_hl(0, "NvimTreeGitIgnored", { link = "Comment" })

			-- Git status colors filename text.
			vim.api.nvim_set_hl(0, "NvimTreeGitFileDirtyHL", { link = "DiagnosticWarn" })
			vim.api.nvim_set_hl(0, "NvimTreeGitFolderDirtyHL", { link = "DiagnosticWarn" })
			vim.api.nvim_set_hl(0, "NvimTreeGitFileStagedHL", { link = "DiagnosticOk" })
			vim.api.nvim_set_hl(0, "NvimTreeGitFolderStagedHL", { link = "DiagnosticOk" })
			vim.api.nvim_set_hl(0, "NvimTreeGitFileNewHL", { link = "DiagnosticOk" })
			vim.api.nvim_set_hl(0, "NvimTreeGitFolderNewHL", { link = "DiagnosticOk" })
			vim.api.nvim_set_hl(0, "NvimTreeGitFileRenamedHL", { link = "Type" })
			vim.api.nvim_set_hl(0, "NvimTreeGitFolderRenamedHL", { link = "Type" })
			vim.api.nvim_set_hl(0, "NvimTreeGitFileDeletedHL", { link = "DiagnosticError" })
			vim.api.nvim_set_hl(0, "NvimTreeGitFolderDeletedHL", { link = "DiagnosticError" })
			vim.api.nvim_set_hl(0, "NvimTreeGitFileMergeHL", { link = "DiagnosticError" })
			vim.api.nvim_set_hl(0, "NvimTreeGitFolderMergeHL", { link = "DiagnosticError" })
			vim.api.nvim_set_hl(0, "NvimTreeGitFileIgnoredHL", { link = "Comment" })
			vim.api.nvim_set_hl(0, "NvimTreeGitFolderIgnoredHL", { link = "Comment" })

			-- Diagnostics color filename text by severity.
			vim.api.nvim_set_hl(0, "NvimTreeDiagnosticErrorFileHL", { link = "DiagnosticError" })
			vim.api.nvim_set_hl(0, "NvimTreeDiagnosticWarnFileHL", { link = "DiagnosticWarn" })
			vim.api.nvim_set_hl(0, "NvimTreeDiagnosticInfoFileHL", { link = "DiagnosticInfo" })
			vim.api.nvim_set_hl(0, "NvimTreeDiagnosticHintFileHL", { link = "DiagnosticHint" })

			-- Diagnostic icons in signcolumn.
			vim.api.nvim_set_hl(0, "NvimTreeDiagnosticErrorIcon", { link = "DiagnosticError" })
			vim.api.nvim_set_hl(0, "NvimTreeDiagnosticWarnIcon", { link = "DiagnosticWarn" })
			vim.api.nvim_set_hl(0, "NvimTreeDiagnosticInfoIcon", { link = "DiagnosticInfo" })
			vim.api.nvim_set_hl(0, "NvimTreeDiagnosticHintIcon", { link = "DiagnosticHint" })
		end

		require("nvim-tree").setup({
			sync_root_with_cwd = true,
			respect_buf_cwd = true,
			update_focused_file = {
				enable = true,
				update_root = true,
			},
			filters = {
				dotfiles = false,
				custom = { "^.git$", "node_modules", ".next", "dist", "build" },
			},
			diagnostics = {
				enable = true,
				show_on_dirs = true,
				show_on_open_dirs = false,
			},
			git = {
				enable = true,
				ignore = false,
			},
			renderer = {
				group_empty = true,
				highlight_git = "name",
				highlight_diagnostics = "name",
				highlight_hidden = "name",
				indent_width = 2,
				indent_markers = {
					enable = true,
					inline_arrows = false,
					icons = {
						corner = "└",
						edge = "│",
						item = "├",
						bottom = "─",
						none = " ",
					},
				},
				special_files = {
					"Cargo.toml",
					"Makefile",
					"README.md",
					"readme.md",
					".env",
					".env.local",
					".env.development",
					".env.production",
					".env.test",
					".gitignore",
					".gitattributes",
					".editorconfig",
					"(group)",
					"(header)",
					"(auth)",
					"[id]",
					"[slug]",
					"[...slug]",
					"[[...slug]]",
					"biome.json",
					"biome.jsonc",
					"tsconfig.json",
					"tsconfig.base.json",
					"jsconfig.json",
					"eslint.config.js",
					"eslint.config.cjs",
					"eslint.config.mjs",
					"eslint.config.ts",
					"prettier.config.js",
					"prettier.config.cjs",
					"prettier.config.mjs",
					"turbo.json",
					"pnpm-workspace.yaml",
				},
				icons = {
					git_placement = "signcolumn",
					glyphs = {
						git = {
							unstaged = " ✗",
							staged = " ✓",
							renamed = " ➜",
							untracked = " ★",
							ignored = " ◌",
							deleted = " ",
							unmerged = " ",
						},
					},
					web_devicons = {
						file = {
							color = false,
						},
						folder = {
							color = false,
						},
					},
					show = {
						git = true,
						folder = true,
						file = true,
						folder_arrow = false,
					},
				},
			},
			actions = {
				open_file = {
					quit_on_open = false,
					resize_window = false,
				},
			},
			view = {
				side = "left",
				preserve_window_proportions = true,
				width = 35,
				adaptive_size = true,
			},
		})

		apply_tree_highlights()
		vim.api.nvim_create_autocmd("ColorScheme", {
			callback = apply_tree_highlights,
		})
	end,
}
