return {
	"goolord/alpha-nvim",
	event = "VimEnter",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		"MaximilianLloyd/ascii.nvim",
	},

	config = function()
		local alpha = require("alpha")
		local dashboard = require("alpha.themes.dashboard")
		local ascii = require("ascii")

		dashboard.section.header.val = ascii.get_random("text", "doom")

		dashboard.section.buttons.val = {
			dashboard.button("e", "  > New file", ":ene <BAR> startinsert <CR>"),
			dashboard.button("f", "  > Find file", "<cmd>Telescope find_files<CR>"),
			dashboard.button("r", "  > Recent", ":Telescope oldfiles<CR>"),
			dashboard.button("s", "  > Settings", "<cmd>edit $MYVIMRC<CR>"),
			dashboard.button("q", "  > Quit Neovim", ":qa<CR>"),
		}

		dashboard.section.footer = {
			type = "text",
			val = function()
				local count = #require("lazy").plugins()
				return {
					"",
					("Loaded %d plugins    Happy hacking!"):format(count),
					"",
				}
			end,
			opts = { hl = "Comment", position = "center" },
		}

		dashboard.opts.layout = {
			{ type = "padding", val = 6 },
			dashboard.section.header,
			dashboard.section.buttons,
			dashboard.section.footer,
		}

		alpha.setup(dashboard.opts)
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "alpha",
			callback = function()
				vim.opt_local.foldenable = false
			end,
		})
	end,
}
