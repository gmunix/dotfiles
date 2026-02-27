return {
	"nvim-lualine/lualine.nvim",
	event = "VeryLazy",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		require("lualine").setup({
			options = {
				icons_enabled = true,
				theme = "auto",
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
				disabled_filetypes = {
					statusline = {},
					winbar = {},
				},
				ignore_focus = {},
				always_divide_middle = true,
				always_show_tabline = false,
				globalstatus = false,
				refresh = {
					statusline = 1000,
					tabline = 1000,
					winbar = 1000,
					refresh_time = 16, -- ~60fps
					events = {
						"WinEnter",
						"BufEnter",
						"BufWritePost",
						"SessionLoadPost",
						"FileChangedShellPost",
						"VimResized",
						"Filetype",
						"CursorMoved",
						"CursorMovedI",
						"ModeChanged",
					},
				},
			},
			sections = {
				lualine_a = {
					{
						"buffers",
						mode = 0,
						show_filename_only = true,
						hide_filename_extension = false,
						show_modified_status = true,
						use_mode_colors = true,
						max_length = function()
							return math.floor(vim.o.columns * 2 / 3)
						end,
						symbols = {
							modified = " ●",
							alternate_file = "",
							directory = "",
						},
					},
				},
				lualine_b = { "mode", "branch", "diff", "diagnostics" },
				lualine_c = {},
				lualine_x = { "encoding", "fileformat", "filetype" },
				lualine_y = { "progress" },
				lualine_z = { "location" },
			},
			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = { "filename" },
				lualine_x = { "location" },
				lualine_y = {},
				lualine_z = {},
			},
			tabline = {
				lualine_a = {
					{
						"tabs",
						mode = 2,
						path = 0,
						use_mode_colors = true,
						show_modified_status = true,
						tab_max_length = 28,
						max_length = function()
							return math.floor(vim.o.columns * 0.95)
						end,
					},
				},
			},
			winbar = {},
			inactive_winbar = {},
			extensions = {},
		})
	end,
}
