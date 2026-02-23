return {
	{
		"kristijanhusak/vim-dadbod-ui",
		dependencies = {
			{ "tpope/vim-dadbod", lazy = true },
			{ "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
		},
		cmd = {
			"DBUI",
			"DBUIToggle",
			"DBUIAddConnection",
			"DBUIFindBuffer",
		},
		keys = {
			{ "<leader>du", "<cmd>DBUIToggle<CR>", desc = "Toggle DB UI" },
			{ "<leader>da", "<cmd>DBUIAddConnection<CR>", desc = "Add DB connection" },
			{ "<leader>df", "<cmd>DBUIFindBuffer<CR>", desc = "Find DB buffer" },
		},
		init = function()
			vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui"
		end,
	},
}
