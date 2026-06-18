local lsp = require("core.lsp")
local tooling = require("core.tooling")

return {
	"elixir-tools/elixir-tools.nvim",
	version = "*",
	ft = { "elixir", "eelixir", "heex", "surface" },
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		if not tooling.has_elixir() then
			vim.notify(
				"elixir/mix missing; skipping elixir-tools setup. Run :DotfilesHealth for details.",
				vim.log.levels.WARN
			)
			return
		end

		local elixir = require("elixir")
		local elixirls = require("elixir.elixirls")
		local elixir_utils = require("elixir.utils")
		local capabilities = lsp.capabilities()
		local mason_bin = vim.fn.stdpath("data") .. "/mason/bin/"

		elixirls.on_attach = function(client, bufnr)
			local add_user_cmd = vim.api.nvim_buf_create_user_command
			add_user_cmd(bufnr, "ElixirFromPipe", elixirls.from_pipe(client), {})
			add_user_cmd(bufnr, "ElixirToPipe", elixirls.to_pipe(client), {})
			add_user_cmd(bufnr, "ElixirRestart", elixirls.restart(client), {})
			add_user_cmd(bufnr, "ElixirExpandMacro", elixirls.expand_macro(client), { range = true })
			add_user_cmd(bufnr, "ElixirOutputPanel", function()
				elixirls.open_output_panel()
			end, {})
		end

		local function on_attach(client, bufnr)
			-- Rely on conform.nvim for formatting to avoid double formatters/diagnostics.
			if client and client.server_capabilities then
				client.server_capabilities.documentFormattingProvider = false
				client.server_capabilities.documentRangeFormattingProvider = false
			end
			lsp.on_attach(client, bufnr)
			local map = function(mode, lhs, rhs, desc)
				vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
			end
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
					fetchDeps = false,
					enableTestLenses = false,
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
