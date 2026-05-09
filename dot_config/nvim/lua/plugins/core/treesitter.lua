local tooling = require("core.tooling")

return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	cond = function()
		return tooling.can_install_treesitter_parsers()
	end,
	lazy = false,
	build = function()
		vim.cmd.TSUpdate()
	end,
	config = function()
		require("nvim-treesitter").setup()

		require("nvim-treesitter").install(tooling.treesitter_parsers)

		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("treesitter_start", { clear = true }),
			callback = function(event)
				pcall(vim.treesitter.start, event.buf)
			end,
		})
	end,
}
