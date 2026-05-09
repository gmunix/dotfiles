local tooling = require("core.tooling")

local formatters_by_ft = {
	lua = { "stylua" },
	["_"] = { "trim_whitespace" },
}

if tooling.has_python() then
	formatters_by_ft.python = { "isort", "black" }
end

if tooling.has_node() then
	local prettier = { "prettierd", "prettier" }
	formatters_by_ft.javascript = prettier
	formatters_by_ft.typescript = prettier
	formatters_by_ft.javascriptreact = prettier
	formatters_by_ft.typescriptreact = prettier
	formatters_by_ft.json = prettier
	formatters_by_ft.yaml = prettier
	formatters_by_ft.markdown = prettier
end

if tooling.has_elixir() then
	formatters_by_ft.elixir = { "mix" }
	formatters_by_ft.heex = { "mix" }
	formatters_by_ft.surface = { "mix" }
	formatters_by_ft.eelixir = { "mix" }
end

return {
	"stevearc/conform.nvim",
	event = { "BufWritePre", "BufNewFile" },
	opts = {
		notify_on_error = false,
		notify_no_formatters = true,
		format_on_save = function(_)
			return { timeout_ms = 2000, lsp_format = "fallback" }
		end,
		formatters_by_ft = formatters_by_ft,
	},
	keys = {
		{
			"<leader>cf",
			function()
				require("conform").format({ async = true, lsp_format = "fallback" })
			end,
			desc = "Format file",
		},
	},
}
