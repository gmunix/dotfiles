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
			{
				"<leader>du",
				function()
					for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
						for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
							local buf = vim.api.nvim_win_get_buf(win)
							if vim.bo[buf].filetype == "dbui" then
								vim.api.nvim_set_current_tabpage(tab)
								vim.api.nvim_set_current_win(win)
								return
							end
						end
					end

					vim.cmd("tabnew")
					vim.cmd("DBUI")
				end,
				desc = "Open DB UI tab",
			},
			{ "<leader>da", "<cmd>DBUIAddConnection<CR>", desc = "Add DB connection" },
			{ "<leader>df", "<cmd>DBUIFindBuffer<CR>", desc = "Find DB buffer" },
		},
		init = function()
			vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui"
		end,
	},
}
