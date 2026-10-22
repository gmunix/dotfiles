-- Loaded with `--cmd` inside the Neovim under test, before the user config.
-- Observes the config from the outside and writes a JSON report to $SMOKE_OUT, then quits.

local out_path = assert(vim.env.SMOKE_OUT, "SMOKE_OUT is required")
local expect = dofile(assert(vim.env.SMOKE_EXPECT, "SMOKE_EXPECT is required"))
local mode = vim.env.SMOKE_MODE or "files"

-- Headless defaults to 80x24, which makes pickers hide their preview window.
vim.o.columns = 200
vim.o.lines = 50

local report = { mode = mode, role = vim.env.SMOKE_ROLE, failures = {}, notes = {}, notifications = {} }

local function fail(kind, message)
	table.insert(report.failures, { kind = kind, message = message })
end

local function note(message)
	table.insert(report.notes, message)
end

-- Capture vim.notify, re-wrapping whenever a plugin replaces it (e.g. nvim-notify).
local wrapped
local function wrap_notify()
	local inner = vim.notify
	wrapped = function(msg, level, opts)
		table.insert(report.notifications, { message = tostring(msg), level = level or vim.log.levels.INFO })
		return inner(msg, level, opts)
	end
	vim.notify = wrapped
end
wrap_notify()
local rewrap_timer = vim.uv.new_timer()
rewrap_timer:start(
	10,
	10,
	vim.schedule_wrap(function()
		if vim.notify ~= wrapped then
			wrap_notify()
		end
	end)
)

local function settle(ms)
	vim.wait(ms, function()
		return false
	end)
end

local runtime = vim.uv.fs_realpath(vim.env.VIMRUNTIME) or vim.env.VIMRUNTIME

local function is_builtin(map)
	local source
	if map.callback then
		source = debug.getinfo(map.callback, "S").source:gsub("^@", "")
	elseif map.sid and map.sid > 0 then
		local info = vim.fn.getscriptinfo({ sid = map.sid })[1]
		source = info and info.name
	end
	if not source then
		return false
	end
	source = vim.uv.fs_realpath(vim.fn.expand(source)) or source
	return source:sub(1, #runtime) == runtime
end

local function custom_maps(mode_name, buf)
	local maps = {}
	local list = buf and vim.api.nvim_buf_get_keymap(buf, mode_name) or vim.api.nvim_get_keymap(mode_name)
	for _, map in ipairs(list) do
		if not is_builtin(map) then
			maps[vim.keycode(map.lhs)] = map
		end
	end
	return maps
end

-- Show mappings the way they are written in the config, with <leader> instead of the raw key.
local function display_lhs(lhs)
	local leader = vim.g.mapleader or "\\"
	if lhs:sub(1, #leader) == leader then
		return "<leader>" .. lhs:sub(#leader + 1)
	end
	return lhs
end

local function check_keymaps()
	for mode_name, lhss in pairs(expect.required_keymaps) do
		local all = {}
		for _, map in ipairs(vim.api.nvim_get_keymap(mode_name)) do
			all[vim.keycode(map.lhs)] = true
		end
		for _, lhs in ipairs(lhss) do
			if not all[vim.keycode(lhs)] then
				fail("keymap", ("missing %s-mode mapping %s"):format(mode_name, lhs))
			end
		end
	end

	for mode_name, lhss in pairs(expect.forbidden_keymaps) do
		local custom = custom_maps(mode_name)
		for _, lhs in ipairs(lhss) do
			if custom[vim.keycode(lhs)] then
				fail("keymap", ("custom %s-mode mapping %s must not exist"):format(mode_name, lhs))
			end
		end
	end

	for mode_name, prefixes in pairs(expect.forbidden_prefixes) do
		local custom = custom_maps(mode_name)
		for _, prefix in ipairs(prefixes) do
			local raw = vim.keycode(prefix)
			for lhs, map in pairs(custom) do
				if lhs:sub(1, #raw) == raw then
					fail(
						"keymap",
						("custom %s-mode mapping %s is under forbidden prefix %s"):format(
							mode_name,
							display_lhs(map.lhs),
							prefix
						)
					)
				end
			end
		end
	end
end

local function check_buffer_keymaps(buf, label)
	for mode_name, lhss in pairs(expect.forbidden_buffer_keymaps) do
		local custom = custom_maps(mode_name, buf)
		for _, lhs in ipairs(lhss) do
			if custom[vim.keycode(lhs)] then
				fail("keymap", ("%s: custom %s-mode buffer mapping %s must not exist"):format(label, mode_name, lhs))
			end
		end
	end
end

local function check_plugins(role)
	local ok, config = pcall(require, "lazy.core.config")
	if not ok then
		fail("plugins", "lazy.nvim is not available")
		return
	end

	local present = {}
	for name, plugin in pairs(config.plugins) do
		if plugin._.cond ~= false then
			present[name] = true
		end
	end
	report.plugins = vim.tbl_keys(present)
	table.sort(report.plugins)

	for _, name in ipairs(expect.removed_plugins) do
		if present[name] then
			fail("plugins", ("plugin %s should be removed"):format(name))
		end
	end
	for _, name in ipairs(expect.roles[role].required_plugins) do
		if not present[name] then
			fail("plugins", ("plugin %s is required for role %s"):format(name, role))
		end
	end
end

local function client_names(buf)
	return vim.tbl_map(function(client)
		return client.name
	end, vim.lsp.get_clients({ bufnr = buf }))
end

local function check_file(file)
	vim.cmd.edit(vim.fn.fnameescape(file.path))
	local buf = vim.api.nvim_get_current_buf()
	local required_servers = {}
	for name, binary in pairs(file.servers or {}) do
		if vim.fn.executable(binary) == 1 then
			required_servers[name] = true
		else
			note(("%s: skipped %s (binary %s not installed)"):format(file.path, name, binary))
		end
	end

	vim.wait(8000, function()
		local names = client_names(buf)
		for name in pairs(required_servers) do
			if not vim.tbl_contains(names, name) then
				return false
			end
		end
		return true
	end, 100)
	settle(1000)

	local names = client_names(buf)
	report.clients = report.clients or {}
	report.clients[file.path] = names
	for name in pairs(required_servers) do
		if not vim.tbl_contains(names, name) then
			fail("lsp", ("%s: %s did not attach"):format(file.path, name))
		end
	end
	for _, name in ipairs(file.forbidden_servers or {}) do
		if vim.tbl_contains(names, name) then
			fail("lsp", ("%s: %s must not attach"):format(file.path, name))
		end
	end
	if #names > 0 then
		check_buffer_keymaps(buf, file.path)
	end
end

local function close_floats()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local ok, config = pcall(vim.api.nvim_win_get_config, win)
		if ok and config.relative ~= "" then
			pcall(vim.api.nvim_win_close, win, true)
		end
	end
	vim.cmd.stopinsert()
end

local function check_pickers()
	for _, lhs in ipairs(expect.picker_keys) do
		local ok, err = pcall(vim.api.nvim_feedkeys, vim.keycode(lhs), "mx", false)
		if not ok then
			fail("picker", ("%s: %s"):format(lhs, err))
		end
		settle(2500)
		close_floats()
		settle(300)
	end
end

local function collect_messages()
	local messages = vim.api.nvim_exec2("messages", { output = true }).output
	report.messages = messages
	for line in messages:gmatch("[^\n]+") do
		for _, pattern in ipairs(expect.error_patterns) do
			if line:find(pattern) then
				fail("message", line)
				break
			end
		end
	end
	for _, item in ipairs(report.notifications) do
		if item.level >= vim.log.levels.WARN then
			fail("notify", item.message)
		end
	end
end

local function run_files()
	local role = report.role or "desktop"
	settle(1500)
	check_plugins(role)
	check_keymaps()
	for _, file in ipairs(expect.files) do
		local ok, err = pcall(check_file, file)
		if not ok then
			fail("file", ("%s: %s"):format(file.path, err))
		end
	end
	check_pickers()
	collect_messages()
end

-- Optional Elixir project check: never writes to disk.
local mix_chatter = { "^==> ", "^Compiling %d+ file", "^Generated ", "^Unchecked dependencies", "^%* " }

local function find_remote_call(buf)
	for row, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
		-- Skip comment lines so the cursor lands on real code.
		local start, _, fun
		if not line:find("^%s*#") then
			start, _, fun = line:find(expect.elixir_call_pattern)
		end
		if start then
			local col = line:find(fun .. "(", start, true)
			return row, col - 1
		end
	end
end

-- Wait until the buffer has stopped changing for a second (formatters may run asynchronously).
local function wait_until_stable(buf, max_ms)
	local tick, since = vim.b[buf].changedtick, vim.uv.now()
	vim.wait(max_ms, function()
		if vim.b[buf].changedtick ~= tick then
			tick, since = vim.b[buf].changedtick, vim.uv.now()
		end
		return vim.uv.now() - since >= 1000
	end, 100)
end

local function run_elixir()
	local timeout = tonumber(vim.env.SMOKE_ELIXIR_TIMEOUT or "300") * 1000
	vim.cmd.edit(vim.fn.fnameescape(assert(vim.env.SMOKE_ELIXIR_FILE)))
	local buf = vim.api.nvim_get_current_buf()
	local original = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

	local client
	vim.wait(math.min(timeout, 60000), function()
		for _, c in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
			if vim.tbl_contains(expect.elixir_servers, c.name) then
				client = c
				return true
			end
		end
		return false
	end, 200)
	if not client then
		fail("elixir", "no Elixir language server attached: " .. table.concat(client_names(buf), ", "))
		collect_messages()
		return
	end
	report.elixir_server = client.name

	local row, col = find_remote_call(buf)
	if not row then
		fail("elixir", "no remote call found in the file to test go-to-definition")
	else
		local params = {
			textDocument = { uri = vim.uri_from_bufnr(buf) },
			position = { line = row - 1, character = col },
		}
		local deadline = vim.uv.now() + timeout
		local found = false
		while vim.uv.now() < deadline and not found do
			local response = client:request_sync("textDocument/definition", params, 10000, buf)
			local result = response and response.result
			found = result ~= nil and (result.uri ~= nil or #result > 0)
			if not found then
				settle(5000)
			end
		end
		report.definition_position = { row, col }
		if not found then
			fail("elixir", ("go-to-definition at %d:%d returned nothing within the timeout"):format(row, col))
		end
	end

	-- Run the format-on-save path without writing the file.
	vim.api.nvim_exec_autocmds("BufWritePre", { buffer = buf })
	wait_until_stable(buf, 30000)
	local formatted = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local before = {}
	for _, line in ipairs(original) do
		before[line] = true
	end
	for _, line in ipairs(formatted) do
		if not before[line] then
			for _, pattern in ipairs(mix_chatter) do
				if line:find(pattern) then
					fail("elixir", "format-on-save inserted Mix output: " .. line)
					break
				end
			end
		end
	end
	vim.bo[buf].modified = false
	collect_messages()
end

vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		vim.schedule(function()
			local ok, err = pcall(mode == "elixir" and run_elixir or run_files)
			if not ok then
				fail("probe", tostring(err))
			end
			rewrap_timer:stop()
			local file = assert(io.open(out_path, "w"))
			file:write(vim.json.encode(report))
			file:close()
			vim.cmd("qall!")
		end)
	end,
})
