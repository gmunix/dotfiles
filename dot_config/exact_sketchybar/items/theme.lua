local colors = require("colors")
local settings = require("settings")

return function(sbar)
  sbar.add("event", "theme_change", "AppleInterfaceThemeChangedNotification")
  sbar.add("event", "theme_colors_updated")

  local observer = sbar.add("item", "theme.observer", {
    drawing = false,
    updates = true,
  })

  observer:subscribe("theme_change", function()
    sbar.exec("defaults read -g AppleInterfaceStyle 2>/dev/null || printf Light", function(result, exit_code)
      if exit_code ~= 0 or type(result) ~= "string" then
        return
      end

      local is_dark = result:lower():match("dark") ~= nil
      if is_dark == colors.is_dark then
        return
      end

      colors.set_dark(is_dark)
      sbar.default(settings.refresh_theme())
      sbar.trigger("theme_colors_updated")
    end)
  end)
end
