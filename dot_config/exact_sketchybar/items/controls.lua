local colors = require("colors")
local icons = require("icons")
local styles = require("styles")

local network_command = [[
if /sbin/route -n get default >/dev/null 2>&1; then
  /usr/bin/printf connected
else
  /usr/bin/printf disconnected
fi
]]

local volume_command = [[
/usr/bin/osascript \
  -e 'set settings to get volume settings' \
  -e 'return (output volume of settings as text) & "," & (output muted of settings as text)'
]]

local toggle_mute_command = [[
muted="$(/usr/bin/osascript -e 'output muted of (get volume settings)')"
if [ "$muted" = true ]; then
  /usr/bin/osascript -e 'set volume without output muted'
else
  /usr/bin/osascript -e 'set volume with output muted'
fi
]]

local battery_command = "/usr/bin/pmset -g batt"

local function status_options(icon, update_freq)
  return {
    position = "right",
    associated_display = "active",
    update_freq = update_freq,
    padding_left = 0,
    padding_right = 0,
    icon = {
      string = icon,
      padding_left = 6,
      padding_right = 3,
    },
    label = {
      string = "--%",
      width = 36,
      align = "right",
      padding_left = 0,
      padding_right = 6,
    },
  }
end

return function(sbar)
  local network_generation = 0
  local volume_generation = 0
  local battery_generation = 0
  local current_volume = 0

  local battery = sbar.add("item", "control.battery", status_options(icons.battery.empty, 120))
  local volume = sbar.add("item", "control.volume", status_options(icons.volume.muted, 0))
  local network = sbar.add("item", "control.network", {
    position = "right",
    associated_display = "active",
    update_freq = 10,
    padding_left = 0,
    padding_right = 0,
    icon = {
      string = icons.network.disconnected,
      color = colors.gray,
      padding_left = 8,
      padding_right = 8,
    },
    label = { drawing = false },
  })

  sbar.add("bracket", "system.controls", {
    network.name,
    volume.name,
    battery.name,
  }, {
    associated_display = "active",
    background = styles.panel(),
  })

  sbar.add("item", "control.separator", {
    position = "right",
    associated_display = "active",
    width = 1,
    padding_left = 0,
    padding_right = 0,
    icon = { drawing = false },
    label = { drawing = false },
  })

  local function refresh_network()
    network_generation = network_generation + 1
    local generation = network_generation

    sbar.exec(network_command, function(result, exit_code)
      if generation ~= network_generation or exit_code ~= 0 then
        return
      end

      local connected = result == "connected"
      network:set({
        icon = {
          string = connected and icons.network.connected or icons.network.disconnected,
          color = connected and colors.aqua or colors.red,
        },
      })
    end)
  end

  local function refresh_volume()
    volume_generation = volume_generation + 1
    local generation = volume_generation

    sbar.exec(volume_command, function(result, exit_code)
      if generation ~= volume_generation or exit_code ~= 0 then
        return
      end

      local level, muted = result:match("^(%d+),(%a+)")
      level = tonumber(level)
      if not level then
        return
      end

      current_volume = math.max(0, math.min(100, level))
      muted = muted == "true"

      local icon = icons.volume.low
      if muted or current_volume == 0 then
        icon = icons.volume.muted
      elseif current_volume >= 60 then
        icon = icons.volume.high
      elseif current_volume >= 30 then
        icon = icons.volume.medium
      end

      volume:set({
        icon = {
          string = icon,
          color = (muted or current_volume == 0) and colors.gray or colors.aqua,
        },
        label = { string = current_volume .. "%" },
      })
    end)
  end

  local function refresh_battery()
    battery_generation = battery_generation + 1
    local generation = battery_generation

    sbar.exec(battery_command, function(result, exit_code)
      if generation ~= battery_generation or exit_code ~= 0 then
        return
      end

      local percentage = tonumber(result:match("(%d+)%%"))
      if not percentage then
        return
      end

      local charging = result:find("; charging;", 1, true) ~= nil
        or result:find("; finishing charge;", 1, true) ~= nil
      local icon = icons.battery.empty
      local color = colors.red

      if charging then
        icon = icons.battery.charging
        color = colors.aqua
      elseif percentage >= 90 then
        icon = icons.battery.full
        color = colors.green
      elseif percentage >= 60 then
        icon = icons.battery.high
        color = colors.green
      elseif percentage >= 40 then
        icon = icons.battery.medium
        color = colors.yellow
      elseif percentage >= 20 then
        icon = icons.battery.low
        color = colors.yellow
      end

      battery:set({
        icon = { string = icon, color = color },
        label = { string = percentage .. "%" },
      })
    end)
  end

  network:subscribe({ "wifi_change", "routine", "system_woke" }, refresh_network)
  volume:subscribe({ "volume_change", "system_woke" }, refresh_volume)
  battery:subscribe({ "power_source_change", "routine", "system_woke" }, refresh_battery)

  network:subscribe("mouse.clicked", function()
    sbar.exec("/usr/bin/open 'x-apple.systempreferences:com.apple.wifi-settings-extension'")
  end)

  volume:subscribe("mouse.clicked", function(env)
    if env.BUTTON == "right" then
      sbar.exec("/usr/bin/open 'x-apple.systempreferences:com.apple.Sound-Settings.extension'")
    else
      sbar.exec(toggle_mute_command, refresh_volume)
    end
  end)

  volume:subscribe("mouse.scrolled", function(env)
    local delta = tonumber(env.SCROLL_DELTA)
    if not delta or delta == 0 then
      return
    end

    local level = math.max(0, math.min(100, current_volume + delta * 5))
    current_volume = level
    sbar.exec("/usr/bin/osascript -e 'set volume output volume " .. level .. "'", refresh_volume)
  end)

  battery:subscribe("mouse.clicked", function()
    sbar.exec("/usr/bin/open 'x-apple.systempreferences:com.apple.Battery-Settings.extension'")
  end)

  refresh_network()
  refresh_volume()
  refresh_battery()
end
