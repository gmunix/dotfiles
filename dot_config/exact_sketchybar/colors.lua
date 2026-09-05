local palettes = {
  dark = {
    bg0 = 0xff2d353b,
    bg1 = 0xff343f44,
    bg2 = 0xff3d484d,
    fg = 0xffd3c6aa,
    gray = 0xff859289,
    red = 0xffe67e80,
    orange = 0xffe69875,
    yellow = 0xffdbbc7f,
    green = 0xffa7c080,
    aqua = 0xff83c092,
    blue = 0xff7fbbb3,
    purple = 0xffd699b6,
  },
  light = {
    bg0 = 0xfffdf6e3,
    bg1 = 0xfff4f0d9,
    bg2 = 0xffefebd4,
    fg = 0xff5c6a72,
    gray = 0xff939f91,
    red = 0xfff85552,
    orange = 0xfff57d26,
    yellow = 0xffdfa000,
    green = 0xff8da101,
    aqua = 0xff35a77c,
    blue = 0xff3a94c5,
    purple = 0xffdf69ba,
  },
}

local colors = { transparent = 0x00000000 }

function colors.with_alpha(color, alpha)
  assert(alpha >= 0 and alpha <= 1, "alpha must be between 0 and 1")
  return (color & 0x00ffffff) | (math.floor(alpha * 255 + 0.5) << 24)
end

function colors.set_dark(is_dark)
  local palette = is_dark and palettes.dark or palettes.light
  for name, value in pairs(palette) do
    colors[name] = value
  end
  colors.is_dark = is_dark
end

function colors.detect_system_dark()
  local handle = io.popen("defaults read -g AppleInterfaceStyle 2>/dev/null || printf Light")
  if not handle then
    return false
  end

  local appearance = (handle:read("*a") or ""):lower()
  handle:close()
  return appearance:match("dark") ~= nil
end

colors.set_dark(colors.detect_system_dark())

return colors
