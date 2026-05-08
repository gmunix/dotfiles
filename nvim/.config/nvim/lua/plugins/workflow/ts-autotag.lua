local tooling = require("core.tooling")

return {
	"windwp/nvim-ts-autotag",
	cond = function()
		return tooling.can_install_treesitter_parsers()
	end,
	event = { "InsertEnter" },
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	config = function()
		require("nvim-ts-autotag").setup({
			filetypes = {
				"astro",
				"css",
				"eelixir",
				"elixir",
				"eruby",
				"gohtml",
				"heex",
				"html",
				"javascript",
				"javascriptreact",
				"less",
				"pug",
				"sass",
				"scss",
				"svelte",
				"typescriptreact",
				"vue",
				"xml",
			},
		})
	end,
}
