-- Override the stylua server definition to prevent it from autostarting as an LSP.
-- We use the CLI formatter via conform.nvim instead of running a stylua language server.
---@type vim.lsp.Config
return {
	autostart = false,
	filetypes = {},
}
