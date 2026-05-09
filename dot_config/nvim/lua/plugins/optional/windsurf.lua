local profile = require("core.profile")

return {
	"Exafunction/windsurf.nvim",
	cond = function()
		return profile.enabled("windsurf")
	end,
	event = "InsertEnter",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"hrsh7th/nvim-cmp",
	},
	config = function()
		require("codeium").setup({
			virtual_text = { enabled = false },
			enable_cmp_source = true,
		})
	end,
}
