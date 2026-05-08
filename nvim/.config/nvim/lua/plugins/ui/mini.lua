return {
	{
		"echasnovski/mini.nvim",
		version = false,
		config = function()
			require("mini.bufremove").setup()
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
