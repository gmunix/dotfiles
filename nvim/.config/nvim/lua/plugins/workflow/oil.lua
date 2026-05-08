return {
	"stevearc/oil.nvim",
	cmd = "Oil",
	keys = {
		{ "<leader>e", "<cmd>Oil<CR>", desc = "Explorer" },
	},
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	---@module 'oil'
	---@type oil.SetupOpts
	opts = {
		default_file_explorer = true,
		columns = { "icon" },
		view_options = {
			show_hidden = true,
		},
	},
}
