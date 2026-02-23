return {
	{
		"mason-org/mason.nvim",
		lazy = false,
		config = function()
			require("mason").setup()
		end,
	},

	{
		"mason-org/mason-lspconfig.nvim",
		lazy = false,
		dependencies = { "mason-org/mason.nvim" },
		opts = {
			ensure_installed = {
				"bashls",
				"cssls",
				"docker_compose_language_service",
				"dockerls",
				"elixirls",
				"emmet_ls",
				"eslint",
				"html",
				"jsonls",
				"lua_ls",
				"marksman",
				"pyright",
				"tailwindcss",
				"taplo",
				"vtsls",
				"yamlls",
			},
			-- We manually configure and enable servers below with vim.lsp.config/enable.
			automatic_enable = false,
		},
	},

	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		lazy = false,
		dependencies = { "mason-org/mason.nvim" },
		opts = {
			ensure_installed = { "prettier", "prettierd", "stylua", "black", "isort", "eslint_d" },
			run_on_start = true,
			start_delay = 3000,
		},
	},

	{
		"neovim/nvim-lspconfig",
		lazy = false,
		dependencies = { "hrsh7th/cmp-nvim-lsp" },
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			-- Disable the stylua LSP entry from nvim-lspconfig. We use the CLI formatter via conform,
			-- and the packaged stylua binary here does not support the --lsp flag.
			vim.lsp.enable("stylua", false)

			local function on_attach(_, bufnr)
				local map = function(mode, lhs, rhs, desc)
					vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
				end
				map("n", "K", vim.lsp.buf.hover, "Hover")
				map("n", "gd", vim.lsp.buf.definition, "Go to definition")
				map("n", "gr", vim.lsp.buf.references, "References")
				map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
				map("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
			end

			local function setup(name, opts)
				local config = vim.tbl_deep_extend("force", {
					capabilities = capabilities,
					on_attach = on_attach,
				}, opts or {})
				vim.lsp.config(name, config)
				vim.lsp.enable(name)
			end

			setup("lua_ls", {
				settings = {
					Lua = {
						diagnostics = { globals = { "vim" } },
						workspace = { checkThirdParty = false },
					},
				},
			})
			setup("pyright")
			setup("vtsls")
			setup("eslint")
			setup("html")
			setup("cssls")
			setup("tailwindcss")
			setup("jsonls")
			setup("yamlls")
			setup("bashls")
			setup("dockerls")
			setup("docker_compose_language_service")
			setup("marksman")
			setup("taplo")
			setup("emmet_ls", {
				filetypes = {
					"astro",
					"css",
					"eruby",
					"gohtml",
					"heex",
					"html",
					"javascriptreact",
					"less",
					"pug",
					"sass",
					"scss",
					"svelte",
					"typescriptreact",
					"vue",
				},
			})
		end,
	},
}
