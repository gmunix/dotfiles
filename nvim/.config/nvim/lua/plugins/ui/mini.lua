return {
	{
		"echasnovski/mini.nvim",
		version = false,
		event = "VimEnter",
		config = function()
			local icons = require("mini.icons")
			icons.setup({ style = "glyph" })
			icons.mock_nvim_web_devicons()
			icons.tweak_lsp_kind()

			require("mini.bufremove").setup()
			require("mini.pairs").setup()
			require("mini.surround").setup({
				mappings = {
					add = "ys",
					delete = "ds",
					find = "",
					find_left = "",
					highlight = "",
					replace = "cs",
					suffix_last = "",
					suffix_next = "",
				},
			})
			vim.keymap.set("x", "S", [[:<C-u>lua MiniSurround.add('visual')<CR>]], { silent = true })
			vim.keymap.set("n", "yss", "ys_", { remap = true, desc = "Surround line" })

			local starter = require("mini.starter")
			starter.setup({
				header = "NEOVIM",
				footer = function()
					return ("Loaded %d plugins"):format(#require("lazy").plugins())
				end,
				items = {
					starter.sections.builtin_actions(),
					{
						{ name = "Find file", action = "Telescope find_files", section = "Telescope" },
						{ name = "Recent files", action = "Telescope oldfiles", section = "Telescope" },
						{ name = "Config", action = "edit $MYVIMRC", section = "Config" },
					},
				},
				content_hooks = {
					starter.gen_hook.adding_bullet(),
					starter.gen_hook.aligning("center", "center"),
				},
			})
		end,
		keys = {
			{
				"<leader>bd",
				function()
					require("mini.bufremove").delete(0, false)
				end,
				desc = "Delete buffer",
			},
			{
				"<leader>bD",
				function()
					require("mini.bufremove").delete(0, true)
				end,
				desc = "Wipeout buffer",
			},
		},
	},
}
