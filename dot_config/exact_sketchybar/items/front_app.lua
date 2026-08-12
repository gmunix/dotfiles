local colors = require("colors")
local commands = require("commands")
local icons = require("icons")
local styles = require("styles")

return function(sbar)
  local refresh_generation = 0
  local front_app = sbar.add("item", "front_app", {
    position = "left",
    associated_display = "active",
    icon = {
      string = icons.app.default,
      color = colors.orange,
    },
    label = {
      string = "Desktop",
      color = colors.fg,
      max_chars = 22,
    },
    background = styles.panel(),
  })

  local function set_app(name)
    if not name or name == "" then
      name = "Desktop"
    end

    front_app:set({
      icon = { string = icons.for_app(name) },
      label = { string = name },
    })
  end

  front_app:subscribe("front_app_switched", function(env)
    refresh_generation = refresh_generation + 1
    set_app(env.INFO)
  end)

  front_app:subscribe("theme_colors_updated", function()
    front_app:set({
      icon = { color = colors.orange },
      label = { color = colors.fg },
      background = styles.panel(),
    })
  end)

  local command = commands.aerospace
    .. " list-windows --focused --json --format '%{app-name}'"

  local function query(generation, attempt)
    sbar.exec(command, function(result, exit_code)
      if generation ~= refresh_generation then
        return
      end

      if exit_code == 0 then
        set_app(type(result) == "table" and result[1] and result[1]["app-name"])
      elseif attempt == 0 then
        sbar.exec("sleep 0.2", function()
          if generation == refresh_generation then
            query(generation, 1)
          end
        end)
      else
        set_app(nil)
      end
    end)
  end

  local function refresh()
    refresh_generation = refresh_generation + 1
    query(refresh_generation, 0)
  end

  front_app:subscribe({
    "aerospace_workspace_change",
    "display_change",
    "system_woke",
  }, refresh)

  refresh()
end
