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
  local network_connected
  local volume_muted = true
  local volume_ready = false
  local battery_percentage
  local battery_charging = false

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

  local panel = sbar.add("bracket", "system.controls", {
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

  local function render_network()
    if network_connected == nil then
      return
    end

    network:set({
      icon = {
        string = network_connected and icons.network.connected or icons.network.disconnected,
        color = network_connected and colors.aqua or colors.red,
      },
    })
  end

  local function refresh_network()
    network_generation = network_generation + 1
    local generation = network_generation

    sbar.exec(network_command, function(result, exit_code)
      if generation ~= network_generation or exit_code ~= 0 then
        return
      end

      network_connected = result == "connected"
      render_network()
    end)
  end

  local function render_volume()
    if not volume_ready then
      return
    end

    local icon = icons.volume.low
    if volume_muted or current_volume == 0 then
      icon = icons.volume.muted
    elseif current_volume >= 60 then
      icon = icons.volume.high
    elseif current_volume >= 30 then
      icon = icons.volume.medium
    end

    volume:set({
      icon = {
        string = icon,
        color = (volume_muted or current_volume == 0) and colors.gray or colors.aqua,
      },
      label = { string = current_volume .. "%" },
    })
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
      volume_muted = muted == "true"
      volume_ready = true
      render_volume()
    end)
  end

  local function render_battery()
    if not battery_percentage then
      return
    end

    local icon = icons.battery.empty
    local color = colors.red

    if battery_charging then
      icon = icons.battery.charging
      color = colors.aqua
    elseif battery_percentage >= 90 then
      icon = icons.battery.full
      color = colors.green
    elseif battery_percentage >= 60 then
      icon = icons.battery.high
      color = colors.green
    elseif battery_percentage >= 40 then
      icon = icons.battery.medium
      color = colors.yellow
    elseif battery_percentage >= 20 then
      icon = icons.battery.low
      color = colors.yellow
    end

    battery:set({
      icon = { string = icon, color = color },
      label = { string = battery_percentage .. "%" },
    })
  end

  local function refresh_battery()
    battery_generation = battery_generation + 1
    local generation = battery_generation

    sbar.exec(battery_command, function(result, exit_code)
      if generation ~= battery_generation or exit_code ~= 0 then
        return
      end

      battery_percentage = tonumber(result:match("(%d+)%%"))
      if not battery_percentage then
        return
      end

      battery_charging = result:find("; charging;", 1, true) ~= nil
        or result:find("; finishing charge;", 1, true) ~= nil
      render_battery()
    end)
  end

  network:subscribe({ "wifi_change", "routine", "system_woke" }, refresh_network)
  volume:subscribe({ "volume_change", "system_woke" }, refresh_volume)
  battery:subscribe({ "power_source_change", "routine", "system_woke" }, refresh_battery)

  battery:subscribe("theme_colors_updated", function()
    panel:set({ background = styles.panel() })
    battery:set({ label = { color = colors.fg } })
    volume:set({ label = { color = colors.fg } })
    render_network()
    render_volume()
    render_battery()
  end)

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
