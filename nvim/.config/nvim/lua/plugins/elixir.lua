return {
	"elixir-tools/elixir-tools.nvim",
	version = "*",
	ft = { "elixir", "eelixir", "heex", "surface" },
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		local elixir = require("elixir")
		local elixirls = require("elixir.elixirls")
		local elixir_utils = require("elixir.utils")
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
			map("n", "<leader>eo", "<cmd>ElixirOutputPanel<CR>", "ElixirLS output")
		end

		local root_warning_group = vim.api.nvim_create_augroup("elixir_tools.root_warning", { clear = true })
		vim.api.nvim_create_autocmd("FileType", {
			group = root_warning_group,
			pattern = { "elixir", "eelixir", "heex", "surface" },
			callback = function(event)
				local path = vim.api.nvim_buf_get_name(event.buf)
				if path == "" or elixir_utils.root_dir(path) then
					return
				end
				if vim.b[event.buf].elixir_root_warning_shown then
					return
				end

				vim.b[event.buf].elixir_root_warning_shown = true
				vim.schedule(function()
					vim.notify(
						"No mix.exs found for this buffer; ElixirLS features like K and gd may be limited.",
						vim.log.levels.WARN
					)
				end)
			end,
		})

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
					fetchDeps = true,
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
