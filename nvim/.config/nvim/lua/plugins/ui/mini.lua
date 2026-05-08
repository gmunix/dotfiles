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
			local header = dashboard.logo

			if profile.enabled("milli") then
				local ok, milli = pcall(require, "milli")
				if ok then
					local milli_opts = {
						splash = profile.pick("milli_splash", "fire"),
						loop = profile.get("milli_loop", true),
					}
					local data_ok, data = pcall(milli.load, milli_opts)
					if data_ok and data and data.frames and data.frames[1] then
						header = table.concat(data.frames[1], "\n")
						milli.starter(milli_opts)
					end
				end
			end

			starter.setup({
				header = header,
				footer = dashboard.footer,
				items = {
					{
						{ name = "Explore", action = "Oil", section = "Start" },
						{ name = "Find file", action = "Telescope find_files", section = "Start" },
						{ name = "Edit config", action = "edit $MYVIMRC", section = "Start" },
						{ name = "Exit", action = "qa", section = "Start" },
					},
				},
				content_hooks = {
					starter.gen_hook.adding_bullet("  "),
					starter.gen_hook.padding(2, 2),
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
