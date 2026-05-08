local lsp = require("core.lsp")
local tooling = require("core.tooling")

return {
	{
		"mason-org/mason.nvim",
		lazy = false,
		opts = {
			max_concurrent_installers = 2,
		},
	},

	{
		"mason-org/mason-lspconfig.nvim",
		lazy = false,
		dependencies = { "mason-org/mason.nvim" },
		opts = {
			ensure_installed = tooling.mason_lsp_servers(),
			-- We manually configure and enable servers below with vim.lsp.config/enable.
			automatic_enable = false,
		},
	},

	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		lazy = false,
		dependencies = { "mason-org/mason.nvim" },
		opts = {
			ensure_installed = tooling.mason_tools(),
			run_on_start = true,
			start_delay = 3000,
		},
	},

	{
		"neovim/nvim-lspconfig",
		lazy = false,
		dependencies = { "hrsh7th/cmp-nvim-lsp" },
		config = function()
			local capabilities = lsp.capabilities()
			local enabled_servers = tooling.enabled_lsp_servers()

			-- Disable the stylua LSP entry from nvim-lspconfig. We use the CLI formatter via conform,
			-- and the packaged stylua binary here does not support the --lsp flag.
			vim.lsp.enable("stylua", false)

			local function setup(name, opts)
				if not enabled_servers[name] then
					return
				end

				local config = vim.tbl_deep_extend("force", {
					capabilities = capabilities,
					on_attach = lsp.on_attach,
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
