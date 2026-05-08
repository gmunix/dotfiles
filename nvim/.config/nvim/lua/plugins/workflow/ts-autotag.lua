return {
	"windwp/nvim-ts-autotag",
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
				"markdown",
				"markdown_inline",
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
