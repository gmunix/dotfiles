return {
	"stevearc/conform.nvim",
	event = { "BufWritePre", "BufNewFile" },
	opts = {
		notify_on_error = false,
		notify_no_formatters = true,
		format_on_save = function(_)
			return { timeout_ms = 2000, lsp_fallback = true }
		end,
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "isort", "black" },
			javascript = { "prettierd", "prettier" },
			typescript = { "prettierd", "prettier" },
			javascriptreact = { "prettierd", "prettier" },
			typescriptreact = { "prettierd", "prettier" },
			elixir = { "mix" },
			heex = { "mix" },
			surface = { "mix" },
			eelixir = { "mix" },
			json = { "prettierd", "prettier" },
			yaml = { "prettierd", "prettier" },
			markdown = { "prettierd", "prettier" },
			["_"] = { "trim_whitespace" },
		},
	},
	keys = {
		{
			"<leader>cf",
			function()
				require("conform").format({ async = true, lsp_fallback = true })
			end,
			desc = "Format file",
		},
	},
}
