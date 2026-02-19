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
				"<leader>a",
				group = "harpoon",
			},
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
				"<leader>d",
				group = "database",
			},
			{
				"<leader>f",
				group = "find",
			},
			{
				"<leader>g",
				group = "git",
			},
			{
				"<leader>r",
				group = "rest/rename",
			},
			{
				"<leader>n",
				group = "noice",
			},
			{
				"<leader>e",
				desc = "Explorer",
			},
		})
	end,
}
