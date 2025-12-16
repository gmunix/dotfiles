return {
	"elixir-tools/elixir-tools.nvim",
	version = "*",
	ft = { "elixir", "eelixir", "heex", "surface" },
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		local elixir = require("elixir")
		local elixirls = require("elixir.elixirls")
		local capabilities = require("cmp_nvim_lsp").default_capabilities()
		local mason_bin = vim.fn.stdpath("data") .. "/mason/bin/"

		local function on_attach(client, bufnr)
			-- Rely on conform.nvim for formatting to avoid double formatters/diagnostics
			if client and client.server_capabilities then
				client.server_capabilities.documentFormattingProvider = false
				client.server_capabilities.documentRangeFormattingProvider = false
			end
			local map = function(mode, lhs, rhs, desc)
				vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
			end
			map("n", "K", vim.lsp.buf.hover, "Hover")
			map("n", "gd", vim.lsp.buf.definition, "Go to definition")
			map("n", "gr", vim.lsp.buf.references, "References")
			map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
			map("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
		end

		elixir.setup({
			nextls = {
				-- Disable Next LS to avoid duplicate diagnostics with elixir-ls.
				enable = false,
				cmd = mason_bin .. "nextls",
				on_attach = on_attach,
				capabilities = capabilities,
			},
			elixirls = {
				enable = true,
				cmd = mason_bin .. "elixir-ls",
				on_attach = on_attach,
				capabilities = capabilities,
				settings = elixirls.settings({
					dialyzerEnabled = false,
					fetchDeps = false,
					enableTestLenses = true,
				}),
			},
			credo = {
				enable = false,
			},
			projectionist = {
				enable = true,
			},
		})
	end,
}
