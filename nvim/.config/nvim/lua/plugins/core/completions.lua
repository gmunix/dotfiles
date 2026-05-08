local profile = require("core.profile")

local function insert_if(sources, condition, source)
	if condition then
		table.insert(sources, source)
	end
end

return {
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"rafamadriz/friendly-snippets",
		},
		config = function()
			local cmp = require("cmp")
			require("luasnip.loaders.from_vscode").lazy_load()

			local primary_sources = {}
			insert_if(primary_sources, profile.enabled("windsurf"), { name = "codeium" })
			vim.list_extend(primary_sources, {
				{ name = "nvim_lsp" },
				{ name = "luasnip" },
				{ name = "path" },
			})

			cmp.setup({
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
				mapping = cmp.mapping.preset.insert({
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
				}),
				sources = cmp.config.sources(primary_sources, {
					{ name = "buffer" },
				}),
			})

			local sql_sources = {}
			insert_if(sql_sources, profile.enabled("dadbod"), { name = "vim-dadbod-completion" })
			vim.list_extend(sql_sources, {
				{ name = "nvim_lsp" },
				{ name = "path" },
			})
			cmp.setup.filetype({ "sql", "mysql", "plsql" }, {
				sources = cmp.config.sources(sql_sources, {
					{ name = "buffer" },
				}),
			})

			local markdown_sources = {}
			if profile.enabled("obsidian") then
				vim.list_extend(markdown_sources, {
					{ name = "obsidian" },
					{ name = "obsidian_new" },
					{ name = "obsidian_tags" },
				})
			end
			insert_if(markdown_sources, profile.enabled("windsurf"), { name = "codeium" })
			vim.list_extend(markdown_sources, {
				{ name = "nvim_lsp" },
				{ name = "luasnip" },
				{ name = "path" },
			})
			cmp.setup.filetype({ "markdown" }, {
				sources = cmp.config.sources(markdown_sources, {
					{ name = "buffer" },
				}),
			})
		end,
	},
}
