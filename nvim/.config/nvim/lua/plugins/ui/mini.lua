local dashboard = require("dotfiles.dashboard")
local profile = require("core.profile")

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
				header = dashboard.logo,
				footer = dashboard.footer,
				items = {
					{
						{ name = "Find file", action = "Telescope find_files", section = "Actions" },
						{ name = "Live grep", action = "Telescope live_grep", section = "Actions" },
						{ name = "Recent files", action = "Telescope oldfiles", section = "Actions" },
						{ name = "Edit config", action = "edit $MYVIMRC", section = "Actions" },
						{ name = "Health check", action = "checkhealth dotfiles", section = "System" },
						{ name = "Lazy", action = "Lazy", section = "System" },
						{ name = "Quit", action = "qa", section = "System" },
					},
				},
				content_hooks = {
					starter.gen_hook.adding_bullet("  "),
					starter.gen_hook.aligning("center", "center"),
				},
			})

			if profile.enabled("milli") then
				local ok, milli = pcall(require, "milli")
				if ok then
					milli.starter({
						splash = profile.get("milli_splash", "fire"),
						loop = profile.get("milli_loop", true),
					})
				end
			end
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
