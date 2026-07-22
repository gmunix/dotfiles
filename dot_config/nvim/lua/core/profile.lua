local M = {}

local defaults = {
	theme = "monokai",
	obsidian = false,
	dadbod = false,
	rest = false,
	neogit = false,
	windsurf = false,
	undo_glow = false,
	milli = false,
	milli_splash = "fire",
	milli_loop = true,
}

local function normalize_env_name(name)
	return name:upper():gsub("[^A-Z0-9]", "_")
end

local function env_value(name)
	local normalized = normalize_env_name(name)
	return vim.env["NVIM_" .. normalized] or vim.env["NVIM_OPTIONAL_" .. normalized]
end

local function env_to_boolean(value)
	if value == nil or value == "" then
		return nil
	end

	value = value:lower()
	if value == "1" or value == "true" or value == "yes" or value == "on" then
		return true
	end
	if value == "0" or value == "false" or value == "no" or value == "off" then
		return false
	end

	return nil
end

local ok, local_profile = pcall(require, "local.profile")
if not ok or type(local_profile) ~= "table" then
	local_profile = {}
end

M.optional = vim.tbl_deep_extend("force", defaults, local_profile)

function M.enabled(name)
	local from_env = env_to_boolean(env_value(name))
	if from_env ~= nil then
		return from_env
	end

	return M.optional[name] == true
end

function M.all()
	return vim.deepcopy(M.optional)
end

function M.get(name, fallback)
	local value = M.optional[name]
	if value == nil then
		return fallback
	end

	return value
end

function M.pick(name, fallback)
	local value = M.get(name, fallback)
	if type(value) ~= "table" then
		return value
	end

	if #value == 0 then
		return fallback
	end

	local index = (vim.uv.hrtime() % #value) + 1
	return value[index]
end

return M
