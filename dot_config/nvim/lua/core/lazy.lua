require("lazy").setup({
	spec = {
		{ import = "plugins.core" },
		{ import = "plugins.ui" },
		{ import = "plugins.workflow" },
		{ import = "plugins.optional" },
	},
	checker = { enabled = false },
	change_detection = {
		enabled = true,
		notify = false,
	},
})
