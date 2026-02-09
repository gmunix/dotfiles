require("lazy").setup({
	spec = {
		{ import = "plugins" },
	},
	checker = { enabled = true },
	change_detection = {
		enabled = true,
		notify = false,
	},
})
