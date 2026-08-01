local settings = require("settings")

return function(sbar)
  sbar.bar(settings.bar)
  sbar.default(settings.default)
end
