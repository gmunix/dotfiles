require("modules.monitors")
require("modules.environment")
require("modules.autostart")
require("modules.appearance")
require("modules.layouts")
require("modules.input")

local apps = require("modules.apps")

require("modules.keybinds").setup(apps)
require("modules.rules")

-- For Noctalia Color templates
local loaded, noctalia = pcall(function()
	return require("noctalia")
end)
if loaded and type(noctalia) == "table" and type(noctalia.apply_theme) == "function" then
	pcall(noctalia.apply_theme)
end
