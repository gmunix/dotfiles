local M = {}

function M.setup(apps)
	local mainMod = "SUPER"

	hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(apps.terminal))
	hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(apps.browser))
	hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(apps.launcher))
	hl.bind(mainMod .. " + W", hl.dsp.window.close())
	hl.bind(
		mainMod .. " + M",
		hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit")
	)
	hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(apps.file_manager))
	hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
	hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(apps.menu))
	hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
	hl.bind(mainMod .. " + CTRL + J", hl.dsp.layout("togglesplit"))
	hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))

	hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
	hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
	hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
	hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

	hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
	hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
	hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
	hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))

	for i = 1, 10 do
		local key = i % 10
		hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
		hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
	end

	hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
	hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

	hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
	hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
	hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
	hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

	hl.bind(
		"XF86AudioRaiseVolume",
		hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
		{ locked = true, repeating = true }
	)
	hl.bind(
		"XF86AudioLowerVolume",
		hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
		{ locked = true, repeating = true }
	)
	hl.bind(
		"XF86AudioMute",
		hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
		{ locked = true, repeating = true }
	)
	hl.bind(
		"XF86AudioMicMute",
		hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
		{ locked = true, repeating = true }
	)
	hl.bind(
		"XF86MonBrightnessUp",
		hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),
		{ locked = true, repeating = true }
	)
	hl.bind(
		"XF86MonBrightnessDown",
		hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),
		{ locked = true, repeating = true }
	)

	hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
	hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
	hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
	hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
end

return M
