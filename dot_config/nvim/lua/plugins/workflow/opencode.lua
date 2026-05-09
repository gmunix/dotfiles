return {
	"nickjvandyke/opencode.nvim",
	version = "*",
	init = function()
		vim.g.opencode_opts = {}
		vim.o.autoread = true
	end,
	keys = {
		{
			"<leader>oa",
			function()
				require("opencode").ask("@this: ", { submit = true })
			end,
			mode = { "n", "x" },
			desc = "Ask opencode",
		},
		{
			"<leader>oo",
			function()
				require("opencode").toggle()
			end,
			desc = "Toggle opencode",
		},
		{
			"<leader>os",
			function()
				require("opencode").select()
			end,
			mode = { "n", "x" },
			desc = "Select opencode action",
		},
	},
}
