local profile = require("core.profile")

return {
	"NeogitOrg/neogit",
	cond = function()
		return profile.enabled("neogit")
	end,
	cmd = "Neogit",
	keys = {
		{
			"<leader>gg",
			function()
				require("neogit").open()
			end,
			desc = "Neogit",
		},
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim",
		"esmuellert/codediff.nvim",
	},
	opts = {
		kind = "tab",
	},
}
