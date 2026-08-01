local colors = require("colors")
local settings = require("settings")

local styles = {}

function styles.panel()
  return {
    drawing = true,
    color = colors.with_alpha(colors.bg1, 0.92),
    border_color = colors.bg2,
    border_width = settings.dimensions.border_width,
    corner_radius = settings.dimensions.corner_radius,
    height = settings.dimensions.item_height,
  }
end

return styles
