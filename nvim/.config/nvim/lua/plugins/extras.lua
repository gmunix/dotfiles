return {
	{
		"karb94/neoscroll.nvim",
		event = "VeryLazy",
		opts = {},
	},
	{
		"eandrju/cellular-automaton.nvim",
		cmd = "CellularAutomaton",
		keys = {
			{ "<leader>cmr", "<cmd>CellularAutomaton make_it_rain<CR>", desc = "Make it rain" },
			{ "<leader>cml", "<cmd>CellularAutomaton game_of_life<CR>", desc = "Game of Life" },
		},
	},
	{
		"ThePrimeagen/vim-be-good",
		cmd = "VimBeGood",
	},
}
