local colors = require("colors")
local commands = require("commands")
local icons = require("icons")
local styles = require("styles")

local function shell_quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local media_poll_interval = 5
local scroll_interval = 45

return function(sbar)
  local refresh_generation = 0
  local failed_refreshes = 0
  local current_label = ""
  local routine_ticks = 0
  local scroll_armed = false
  local source_app
  local source_bundle

  local media = sbar.add("item", "media", {
    position = "right",
    associated_display = "active",
    drawing = false,
    update_freq = 1,
    scroll_texts = false,
    padding_right = 1,
    icon = {
      string = icons.media.paused,
      color = colors.gray,
    },
    label = {
      color = colors.fg,
      max_chars = 28,
      scroll_duration = 120,
    },
    background = styles.panel(),
  })

  local function hide()
    source_app = nil
    source_bundle = nil
    current_label = ""
    routine_ticks = 0
    scroll_armed = false
    media:set({ drawing = false, scroll_texts = false })
  end

  local function update(info)
    if type(info) ~= "table" or not info.title or info.title == "" then
      hide()
      return
    end

    local artist = info.artist or ""
    local label = info.title
    if artist ~= "" then
      label = label .. " - " .. artist
    end

    if label ~= current_label then
      current_label = label
      routine_ticks = 0
      scroll_armed = false
      media:set({ scroll_texts = false })
    end

    local playing = info.state == "playing"
      or tonumber(info.playbackRate or 0) > 0

    if info.app then
      source_app = info.app
    end
    if info.clientBundleIdentifier then
      source_bundle = info.clientBundleIdentifier
    end

    failed_refreshes = 0
    media:set({
      drawing = true,
      icon = {
        string = playing and icons.media.playing or icons.media.paused,
        color = playing and colors.aqua or colors.gray,
      },
      label = { string = label },
    })
  end

  local query_command = commands.nowplaying
    .. " get --json title artist playbackRate clientBundleIdentifier"

  local function refresh()
    refresh_generation = refresh_generation + 1
    local generation = refresh_generation

    sbar.exec(query_command, function(result, exit_code)
      if generation ~= refresh_generation then
        return
      end

      if exit_code == 0 and type(result) == "table" then
        update(result)
      else
        failed_refreshes = failed_refreshes + 1
        if failed_refreshes >= 2 then
          hide()
        end
      end
    end)
  end

  media:subscribe("media_change", function(env)
    refresh_generation = refresh_generation + 1
    update(env.INFO)
    refresh()
  end)

  media:subscribe("routine", function()
    routine_ticks = routine_ticks + 1

    if scroll_armed then
      scroll_armed = false
      media:set({ scroll_texts = false })
    elseif routine_ticks % scroll_interval == 0 then
      scroll_armed = true
      media:set({ scroll_texts = true })
    end

    if routine_ticks % media_poll_interval == 0 then
      refresh()
    end
  end)

  media:subscribe("system_woke", refresh)

  media:subscribe("mouse.clicked", function(env)
    if env.BUTTON == "left" then
      sbar.exec(commands.nowplaying .. " togglePlayPause", refresh)
    elseif env.BUTTON == "middle" then
      sbar.exec(commands.nowplaying .. " next", refresh)
    elseif env.BUTTON == "right" then
      if source_bundle then
        sbar.exec("open -b " .. shell_quote(source_bundle))
      elseif source_app then
        sbar.exec("open -a " .. shell_quote(source_app))
      end
    end
  end)

  refresh()
end
