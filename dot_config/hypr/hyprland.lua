require("modules.monitors")
require("modules.environment")
require("modules.autostart")
require("modules.appearance")
require("modules.layouts")
require("modules.input")

local apps = require("modules.apps")

require("modules.keybinds").setup(apps)
require("modules.rules")
