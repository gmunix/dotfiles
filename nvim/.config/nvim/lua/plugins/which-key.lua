return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		preset = "helix",
	},
	config = function(_, opts)
		local wk = require("which-key")
		wk.setup(opts)
		wk.add({
			{
				"<leader>?",
				function()
					wk.show({ global = false })
				end,
				desc = "buffer local keymaps (which-key)",
			},
			{
				"<leader>b",
				group = "buffer",
			},
			{
				"<leader>c",
				group = "code",
			},
			{
				"<leader>f",
				group = "find",
			},
			{
				"<leader>g",
				group = "goto",
			},
			{
				"<leader>r",
				group = "rest",
			},
			{
				"<leader>n",
				group = "noice",
			},
		})
	end,
}
