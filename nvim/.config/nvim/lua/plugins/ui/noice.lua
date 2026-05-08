return {
	"folke/noice.nvim",
	event = "VeryLazy",
	keys = {
		{ "<leader>nd", "<cmd>NoiceDismiss<CR>", desc = "Dismiss notifications" },
	},
	dependencies = {
		"MunifTanjim/nui.nvim",
		"rcarriga/nvim-notify",
	},
	config = function()
		local notify = require("notify")
		notify.setup({
			background_colour = "#000000",
		})
		vim.notify = notify

		require("noice").setup({
			lsp = {
				hover = { silent = false },
			},
			presets = {
				bottom_search = true,
				command_palette = false,
				long_message_to_split = true,
				inc_rename = false,
				lsp_doc_border = false,
			},
		})
	end,
}
