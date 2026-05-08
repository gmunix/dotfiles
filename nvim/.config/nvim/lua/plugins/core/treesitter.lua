local tooling = require("core.tooling")

return {
	"nvim-treesitter/nvim-treesitter",
	build = function()
		if tooling.has_compiler() then
			vim.cmd.TSUpdate()
		end
	end,
	config = function()
		local config = require("nvim-treesitter.configs")
		config.setup({
			ensure_installed = tooling.treesitter_ensure_installed(),
			auto_install = tooling.has_compiler(),
			highlight = { enable = true },
			indent = { enable = true },
		})
	end,
}
