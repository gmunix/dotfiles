local colors = require("colors")
local icons = require("icons")
local styles = require("styles")

local cpu_command = [[
set -e
set -o pipefail
cores="$(/usr/sbin/sysctl -n hw.ncpu 2>/dev/null)"
/bin/ps -A -o %cpu= | /usr/bin/awk -v cores="$cores" '
  { sum += $1 }
  END {
    usage = cores > 0 ? sum / cores : 0
    if (usage > 100) usage = 100
    printf "%.0f", usage
  }
'
]]

local ram_command = [[
set -e
set -o pipefail
page_size="$(/usr/bin/pagesize 2>/dev/null)"
total_bytes="$(/usr/sbin/sysctl -n hw.memsize 2>/dev/null)"
/usr/bin/vm_stat | /usr/bin/awk -v page_size="$page_size" -v total_bytes="$total_bytes" '
  /Pages active/ { active = $3 }
  /Pages wired down/ { wired = $4 }
  /Pages occupied by compressor/ { compressed = $5 }
  END {
    gsub(/\./, "", active)
    gsub(/\./, "", wired)
    gsub(/\./, "", compressed)
    usage = total_bytes > 0 ? ((active + wired + compressed) * page_size / total_bytes) * 100 : 0
    if (usage > 100) usage = 100
    printf "%.0f", usage
  }
'
]]

local function metric_color(value)
  if value >= 85 then
    return colors.red
  elseif value >= 65 then
    return colors.yellow
  end
  return colors.green
end

local function item_options(icon, update_freq)
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
  local cpu_failures = 0
  local cpu_generation = 0
  local ram_failures = 0
  local ram_generation = 0

  local ram = sbar.add("item", "system.ram", item_options(icons.system.ram, 15))
  local cpu = sbar.add("item", "system.cpu", item_options(icons.system.cpu, 5))

  sbar.add("bracket", "system.metrics", { cpu.name, ram.name }, {
    associated_display = "active",
    background = styles.panel(),
  })

  local function update(item, result)
    local value = tonumber(result)
    if not value then
      return
    end

    value = math.max(0, math.min(100, math.floor(value + 0.5)))
    item:set({
      icon = { color = metric_color(value) },
      label = { string = value .. "%" },
    })
    return true
  end

  local function unavailable(item)
    item:set({
      icon = { color = colors.gray },
      label = { string = "--%" },
    })
  end

  local function refresh_cpu()
    cpu_generation = cpu_generation + 1
    local generation = cpu_generation

    sbar.exec(cpu_command, function(result, exit_code)
      if generation ~= cpu_generation then
        return
      end

      if exit_code == 0 and update(cpu, result) then
        cpu_failures = 0
      else
        cpu_failures = cpu_failures + 1
        if cpu_failures >= 2 then
          unavailable(cpu)
        end
      end
    end)
  end

  local function refresh_ram()
    ram_generation = ram_generation + 1
    local generation = ram_generation

    sbar.exec(ram_command, function(result, exit_code)
      if generation ~= ram_generation then
        return
      end

      if exit_code == 0 and update(ram, result) then
        ram_failures = 0
      else
        ram_failures = ram_failures + 1
        if ram_failures >= 2 then
          unavailable(ram)
        end
      end
    end)
  end

  cpu:subscribe({ "routine", "system_woke" }, refresh_cpu)
  ram:subscribe({ "routine", "system_woke" }, refresh_ram)

  local function open_activity_monitor()
    sbar.exec("/usr/bin/open -a 'Activity Monitor'")
  end

  cpu:subscribe("mouse.clicked", open_activity_monitor)
  ram:subscribe("mouse.clicked", open_activity_monitor)

  refresh_cpu()
  refresh_ram()
end
