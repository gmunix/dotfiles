local colors = require("colors")
local commands = require("commands")
local settings = require("settings")
local styles = require("styles")

local workspace_ids = { "1", "2", "3", "4", "5", "6", "7", "8", "9" }
local workspace_width = 26

return function(sbar)
	local refresh_generation = 0
	local items = {}
	local states = {}
	local item_names = {}

	local function render(workspace)
		local item = items[workspace]
		local state = states[workspace]
		if not item or not state then
			return
		end

		local label_color = colors.gray
		local background_color = colors.transparent
		local border_color = colors.transparent

		if state.focused then
			label_color = colors.bg0
			background_color = colors.green
			border_color = colors.green
		elseif state.occupied then
			label_color = colors.fg
		end

		local properties = {
			drawing = state.present,
			label = { color = label_color },
			background = {
				color = background_color,
				border_color = border_color,
			},
		}

		if state.display then
			properties.associated_display = state.display
		end

		item:set(properties)
	end

	local function render_all()
		for _, workspace in ipairs(workspace_ids) do
			render(workspace)
		end
	end

	for _, workspace in ipairs(workspace_ids) do
		states[workspace] = {
			focused = false,
			occupied = false,
			present = true,
		}

		local item = sbar.add("item", "workspace." .. workspace, {
			position = "left",
			width = workspace_width,
			padding_left = 1,
			padding_right = 1,
			icon = { drawing = false },
			label = {
				string = workspace,
				width = workspace_width,
				align = "center",
				padding_left = 0,
				padding_right = 0,
			},
			background = {
				drawing = true,
				color = colors.transparent,
				border_color = colors.transparent,
				border_width = settings.dimensions.border_width,
				corner_radius = settings.dimensions.corner_radius - 1,
				height = settings.dimensions.item_height - 4,
			},
		})

		items[workspace] = item
		item_names[#item_names + 1] = item.name

		item:subscribe("mouse.clicked", function()
			sbar.exec(commands.aerospace .. " workspace " .. workspace)
		end)
	end

	local rail = sbar.add("bracket", "workspace.rail", item_names, {
		background = styles.panel(),
	})

	local workspace_command = commands.aerospace
		.. " list-workspaces --all --json"
		.. " --format '%{workspace} %{monitor-appkit-nsscreen-screens-id}"
		.. " %{workspace-is-focused}'"

	local window_command = commands.aerospace .. " list-windows --all --json --format '%{workspace}'"

	local function refresh_workspaces(generation)
		sbar.exec(workspace_command, function(result, exit_code)
			if generation ~= refresh_generation or exit_code ~= 0 or type(result) ~= "table" then
				return
			end

			local present = {}
			for _, row in ipairs(result) do
				local workspace = tostring(row.workspace)
				local state = states[workspace]
				if state then
					present[workspace] = true
					state.present = true
					state.display = tonumber(row["monitor-appkit-nsscreen-screens-id"])
					state.focused = row["workspace-is-focused"] == true
				end
			end

			for _, workspace in ipairs(workspace_ids) do
				if not present[workspace] then
					states[workspace].present = false
				end
			end

			render_all()
		end)
	end

	local function refresh_occupancy(generation)
		sbar.exec(window_command, function(result, exit_code)
			if generation ~= refresh_generation or exit_code ~= 0 or type(result) ~= "table" then
				return
			end

			for _, workspace in ipairs(workspace_ids) do
				states[workspace].occupied = false
			end

			for _, row in ipairs(result) do
				local workspace = tostring(row.workspace)
				if states[workspace] then
					states[workspace].occupied = true
				end
			end

			render_all()
		end)
	end

	local function refresh()
		refresh_generation = refresh_generation + 1
		refresh_workspaces(refresh_generation)
		refresh_occupancy(refresh_generation)
	end

	sbar.add("event", "aerospace_workspace_change")

	local observer = sbar.add("item", "workspace.observer", {
		drawing = false,
		update_freq = 10,
	})

	observer:subscribe({
		"aerospace_workspace_change",
		"display_change",
		"space_windows_change",
		"system_woke",
		"routine",
		"theme_colors_updated",
	}, function(env)
		if env.SENDER == "theme_colors_updated" then
			rail:set({ background = styles.panel() })
			render_all()
			return
		end

		if env.SENDER == "aerospace_workspace_change" and env.FOCUSED_WORKSPACE then
			for _, workspace in ipairs(workspace_ids) do
				states[workspace].focused = workspace == env.FOCUSED_WORKSPACE
			end
			render_all()
		end

		refresh()
	end)

	refresh()
end
