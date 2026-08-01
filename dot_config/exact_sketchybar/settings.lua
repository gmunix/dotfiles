local colors = require("colors")

local fonts = {
  icon = {
    family = "JetBrainsMono Nerd Font",
    style = "Bold",
    size = 15.0,
  },
  label = {
    family = "JetBrainsMono Nerd Font",
    style = "Medium",
    size = 13.0,
  },
}

local dimensions = {
  bar_height = 36,
  item_height = 28,
  corner_radius = 5,
  border_width = 1,
}

local settings = {
  fonts = fonts,
  dimensions = dimensions,
  bar = {
    position = "top",
    height = dimensions.bar_height,
    color = colors.transparent,
    shadow = false,
    sticky = true,
    padding_left = 8,
    padding_right = 8,
  },
  default = {
    padding_left = 3,
    padding_right = 3,
    icon = {
      font = fonts.icon,
      color = colors.green,
      padding_left = 7,
      padding_right = 4,
    },
    label = {
      font = fonts.label,
      color = colors.fg,
      padding_left = 4,
      padding_right = 7,
    },
  },
}

return settings
