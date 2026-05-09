local search_ignores = require("core.search_ignores")

return {
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		cmd = "Telescope",
		keys = {
			{
				"<leader>ff",
				function()
					require("telescope.builtin").find_files()
				end,
				desc = "Find files",
			},
			{
				"<leader>fg",
				function()
					require("telescope.builtin").live_grep()
				end,
				desc = "Live grep",
			},
			{
				"<leader>fF",
				function()
					require("telescope.builtin").find_files({
						hidden = true,
						no_ignore = true,
						no_ignore_parent = true,
						find_command = search_ignores.rg_find_files_command(),
					})
				end,
				desc = "Find files (hidden + ignored)",
			},
			{
				"<leader>fG",
				function()
					require("telescope.builtin").live_grep({
						additional_args = function()
							return search_ignores.rg_additional_args()
						end,
					})
				end,
				desc = "Live grep (hidden + ignored)",
			},
			{
				"<leader>fb",
				function()
					require("telescope.builtin").buffers()
				end,
				desc = "Open buffers",
			},
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-ui-select.nvim",
		},
		opts = function()
			return {
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown({}),
					},
				},
				pickers = {
					find_files = {
						hidden = true,
					},
				},
			}
		end,
		config = function(_, opts)
			local telescope = require("telescope")
			telescope.setup(opts)
			pcall(telescope.load_extension, "ui-select")
		end,
	},
}
