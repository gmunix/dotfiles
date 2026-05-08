local tooling = require("core.tooling")

return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = function()
		if tooling.can_install_treesitter_parsers() then
			vim.cmd.TSUpdate()
		end
	end,
	config = function()
		require("nvim-treesitter").setup()

		if not tooling.can_install_treesitter_parsers() then
			return
		end

		require("nvim-treesitter").install(tooling.treesitter_parsers)

		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("treesitter_start", { clear = true }),
			callback = function(event)
				pcall(vim.treesitter.start, event.buf)
			end,
		})
	end,
}
