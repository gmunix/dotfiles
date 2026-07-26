local profile = require("core.profile")
local use_noctalia = profile.get("theme", "monokai") == "noctalia"

return {
	"gthelding/monokai-pro.nvim",
	lazy = false,
	priority = 1000,
	dependencies = {
		{ "RRethy/base16-nvim", enabled = use_noctalia },
	},
	config = function()
		if use_noctalia then
			local loaded, matugen = pcall(require, "matugen")
			if loaded and type(matugen) == "table" and type(matugen.setup) == "function" and pcall(matugen.setup) then
				return
			end
		end

		require("monokai-pro").setup({
			transparent_background = true,
			filter = "ristretto",
			override = function()
				return {
					NonText = { fg = "#948a8b" },
					MiniIconsGrey = { fg = "#948a8b" },
					MiniIconsRed = { fg = "#fd6883" },
					MiniIconsBlue = { fg = "#85dacc" },
					MiniIconsGreen = { fg = "#adda78" },
					MiniIconsYellow = { fg = "#f9cc6c" },
					MiniIconsOrange = { fg = "#f38d70" },
					MiniIconsPurple = { fg = "#a8a9eb" },
					MiniIconsAzure = { fg = "#a8a9eb" },
					MiniIconsCyan = { fg = "#85dacc" },
				}
			end,
		})
		vim.cmd.colorscheme("monokai-pro")
	end,
}
