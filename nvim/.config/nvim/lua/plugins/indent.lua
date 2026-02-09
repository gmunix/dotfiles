return {
	"lukas-reineke/indent-blankline.nvim",
	main = "ibl",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		require("ibl").setup({
			exclude = {
				filetypes = { "help", "alpha", "neo-tree", "oil", "Trouble", "lazy" },
			},
		})
	end,
}
