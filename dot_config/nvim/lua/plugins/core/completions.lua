local profile = require("core.profile")

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
			if profile.enabled("dadbod") then
				table.insert(sql_sources, { name = "vim-dadbod-completion" })
			end
			vim.list_extend(sql_sources, {
				{ name = "nvim_lsp" },
				{ name = "path" },
			})
			cmp.setup.filetype({ "sql", "mysql", "plsql" }, {
				sources = cmp.config.sources(sql_sources, {
					{ name = "buffer" },
				}),
			})
		end,
	},
}
