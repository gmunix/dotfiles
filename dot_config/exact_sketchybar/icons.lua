local icons = {
	app = {
		default = "󰣆",
		ChatGPT = "󰭹",
		Finder = "󰀶",
		Ghostty = "",
		Safari = "󰀹",
		Spotify = "",
		WhatsApp = "",
		Zen = "󰈹",
	},
}

function icons.for_app(name)
	if not name or name == "" then
		return icons.app.default
	end

	if icons.app[name] then
		return icons.app[name]
	end

	for app, icon in pairs(icons.app) do
		if app ~= "default" and name:find(app, 1, true) then
			return icon
		end
	end

	return icons.app.default
end

return icons
