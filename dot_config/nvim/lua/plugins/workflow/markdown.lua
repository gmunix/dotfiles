local tooling = require("core.tooling")

return {
	"MeanderingProgrammer/render-markdown.nvim",
	cond = function()
		return tooling.can_install_treesitter_parsers()
	end,
	ft = { "markdown" },
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	---@module 'render-markdown'
	---@type render.md.UserConfig
	opts = {},
}
