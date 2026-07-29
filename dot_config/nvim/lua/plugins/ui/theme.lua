return {
	"polirritmico/monokai-nightasty.nvim",
	lazy = false,
	priority = 1000,
	opts = {
		dark_style_background = "transparent",
		light_style_background = "transparent",
	},
	config = function(_, opts)
		require("monokai-nightasty").load(opts)
	end,
}
