require("lazy").setup({
	spec = {
		{ import = "plugins" },
	},
	checker = { enabled = false },
	change_detection = {
		enabled = true,
		notify = false,
	},
})
