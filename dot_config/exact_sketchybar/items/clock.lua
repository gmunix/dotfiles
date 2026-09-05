local colors = require("colors")
local settings = require("settings")
local styles = require("styles")

local calendar_rows = 8

return function(sbar)
  local calendar_generation = 0
  local last_minute

  local clock = sbar.add("item", "clock", {
    position = "right",
    associated_display = "active",
    update_freq = 1,
    padding_left = 0,
    icon = {
      color = colors.fg,
      font = settings.fonts.label,
      width = 64,
      align = "right",
    },
    label = {
      color = colors.fg,
      width = 52,
      align = "right",
    },
    background = styles.panel(),
    popup = {
      align = "right",
      y_offset = 4,
      height = 22,
      blur_radius = 20,
      background = {
        color = colors.with_alpha(colors.bg0, 0.96),
        border_color = colors.bg2,
        border_width = settings.dimensions.border_width,
        corner_radius = settings.dimensions.corner_radius,
      },
    },
  })

  sbar.add("item", "clock.separator", {
    position = "right",
    associated_display = "active",
    width = 1,
    padding_left = 0,
    padding_right = 0,
    icon = { drawing = false },
    label = { drawing = false },
  })

  local rows = {}
  for index = 1, calendar_rows do
    rows[index] = sbar.add("item", "clock.calendar." .. index, {
      position = "popup." .. clock.name,
      icon = { drawing = false },
      label = {
        string = "",
        color = index == 2 and colors.gray or colors.fg,
        font = settings.fonts.label,
        width = 190,
        align = "left",
        padding_left = 8,
        padding_right = 8,
      },
    })

    rows[index]:subscribe("mouse.clicked", function()
      calendar_generation = calendar_generation + 1
      clock:set({ popup = { drawing = false } })
    end)
  end

  local function update_clock(force)
    local minute = os.date("%Y-%m-%d %H:%M")
    if not force and minute == last_minute then
      return
    end

    last_minute = minute
    clock:set({
      icon = { string = os.date("%d %b"):upper() },
      label = { string = os.date("%H:%M") },
    })
  end

  local function update_calendar()
    calendar_generation = calendar_generation + 1
    local generation = calendar_generation

    sbar.exec("/usr/bin/cal", function(result, exit_code)
      if generation ~= calendar_generation
        or exit_code ~= 0
        or type(result) ~= "string"
      then
        return
      end

      local lines = {}
      for line in (result .. "\n"):gmatch("(.-)\n") do
        lines[#lines + 1] = line
      end

      for index, row in ipairs(rows) do
        row:set({ label = { string = lines[index] or "" } })
      end
    end)
  end

  clock:subscribe("routine", function()
    update_clock(false)
  end)

  clock:subscribe("system_woke", function()
    update_clock(true)
    update_calendar()
  end)

  clock:subscribe("theme_colors_updated", function()
    clock:set({
      icon = { color = colors.fg },
      label = { color = colors.fg },
      background = styles.panel(),
      popup = {
        background = {
          color = colors.with_alpha(colors.bg0, 0.96),
          border_color = colors.bg2,
        },
      },
    })

    for index, row in ipairs(rows) do
      row:set({ label = { color = index == 2 and colors.gray or colors.fg } })
    end
  end)

  clock:subscribe("mouse.clicked", function(env)
    if env.BUTTON == "right" then
      sbar.exec("/usr/bin/open -a 'Calendar'")
      return
    end

    local popup = clock:query().popup
    local should_open = popup.drawing ~= "on"
    if should_open then
      update_calendar()
    else
      calendar_generation = calendar_generation + 1
    end
    clock:set({ popup = { drawing = should_open } })
  end)

  update_clock(true)
end
