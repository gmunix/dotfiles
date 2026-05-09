local profile = require("core.profile")

return {
	"amansingh-afk/milli.nvim",
	cond = function()
		return profile.enabled("milli")
	end,
}
