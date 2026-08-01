local colors = {
  transparent = 0x00000000,
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
}

function colors.with_alpha(color, alpha)
  assert(alpha >= 0 and alpha <= 1, "alpha must be between 0 and 1")
  return (color & 0x00ffffff) | (math.floor(alpha * 255 + 0.5) << 24)
end

return colors
