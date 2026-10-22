-- Headless smoke test for the Neovim config.
--
-- Usage (from the dotfiles repo):
--   nvim -l tests/nvim/smoke.lua [--role desktop|server|all] [--elixir <mix-project-or-file>]
--
-- Renders the config from this source tree with chezmoi into a scratch destination (your home is
-- untouched), then runs Neovim headless against it once per role. Plugins and Mason packages are
-- shared with your normal install; logs and state go to the scratch directory.

local here = vim.fs.dirname(vim.fs.abspath(debug.getinfo(1, "S").source:sub(2)))
local repo = vim.fs.dirname(vim.fs.dirname(here))
local probe = vim.fs.joinpath(here, "probe.lua")
local expect_path = vim.fs.joinpath(here, "expectations.lua")
local fixtures = vim.fs.joinpath(here, "fixtures")
local expect = dofile(expect_path)

local args = { role = "all" }
do
	local i = 1
	while i <= #_G.arg do
		local a = _G.arg[i]
		local value = _G.arg[i + 1]
		if a == "--role" or a == "--elixir" then
			if not value or value:sub(1, 2) == "--" then
				io.stderr:write(a .. " needs a value\n")
				os.exit(2)
			end
			args[a:sub(3)] = value
			i = i + 2
		else
			io.stderr:write("unknown argument: " .. a .. "\n")
			os.exit(2)
		end
	end
end

local function run(cmd, opts)
	return vim.system(cmd, vim.tbl_extend("force", { text = true }, opts or {})):wait()
end

local function render(role)
	local dest = vim.fn.tempname()
	vim.fn.mkdir(vim.fs.joinpath(dest, ".config"), "p")
	local result = run({
		"chezmoi",
		"apply",
		"--source",
		repo,
		"--destination",
		dest,
		"--persistent-state",
		vim.fs.joinpath(dest, "chezmoistate.boltdb"),
		"--exclude",
		"scripts",
		"--override-data",
		vim.json.encode({ machine = { role = role } }),
		vim.fs.joinpath(dest, ".config", "nvim"),
	})
	if result.code ~= 0 then
		error("chezmoi render failed:\n" .. result.stderr)
	end
	return dest
end

local function nvim_env(dest, extra)
	return vim.tbl_extend("force", {
		XDG_CONFIG_HOME = vim.fs.joinpath(dest, ".config"),
		XDG_STATE_HOME = vim.fs.joinpath(dest, "state"),
	}, extra or {})
end

local function startup_ms(dest)
	local log = vim.fs.joinpath(dest, "startuptime.log")
	local times = {}
	for i = 1, 5 do
		vim.fn.delete(log)
		run({ "nvim", "--headless", "--startuptime", log, "+qall!" }, { env = nvim_env(dest), cwd = fixtures })
		local content = table.concat(vim.fn.readfile(log), "\n")
		local ms = content:match("([%d.]+)%s+[%d.]+: %-%-%- NVIM STARTED %-%-%-")
		-- The first run warms the module cache; it is not counted.
		if i > 1 and ms then
			table.insert(times, tonumber(ms))
		end
	end
	table.sort(times)
	return times[1]
end

local function probe_run(dest, env, cwd, timeout)
	local out = vim.fs.joinpath(dest, "report.json")
	local result = run({ "nvim", "--headless", "--cmd", "luafile " .. probe }, {
		env = nvim_env(dest, vim.tbl_extend("force", { SMOKE_OUT = out, SMOKE_EXPECT = expect_path }, env)),
		cwd = cwd,
		timeout = timeout,
	})
	local ok, report = pcall(function()
		return vim.json.decode(table.concat(vim.fn.readfile(out), "\n"))
	end)
	if not ok then
		-- vim.system reports exit code 124 when it kills the process on timeout.
		local reason = result.code == 124 and ("timed out after %d s"):format(timeout / 1000)
			or ("exit " .. result.code)
		report = {
			failures = { { kind = "probe", message = "no report produced (" .. reason .. ")" } },
			notes = {},
		}
	end
	for line in (result.stderr or ""):gmatch("[^\r\n]+") do
		-- Messages already reported by the probe are echoed to stderr too; report them once.
		local known = report.messages and report.messages:find(line, 1, true)
		for _, pattern in ipairs(known and {} or expect.error_patterns) do
			if line:find(pattern) then
				table.insert(report.failures, { kind = "stderr", message = line })
				break
			end
		end
	end
	return report
end

-- Collapse repeated failures (e.g. the same error printed many times) into one line with a count.
local function print_failures(failures)
	local seen, order = {}, {}
	for _, f in ipairs(failures) do
		local key = ("[%s] %s"):format(f.kind, f.message)
		if not seen[key] then
			table.insert(order, key)
		end
		seen[key] = (seen[key] or 0) + 1
	end
	for _, key in ipairs(order) do
		print("  FAIL " .. key .. (seen[key] > 1 and (" (x%d)"):format(seen[key]) or ""))
	end
end

local failed = false

local function finish(report, dest)
	print(#report.failures == 0 and "  PASS" or ("  %d failure(s)"):format(#report.failures))
	failed = failed or #report.failures > 0
	vim.fn.delete(dest, "rf")
end

local function report_role(role)
	print(("== role: %s"):format(role))
	local dest = render(role)
	local report = probe_run(dest, { SMOKE_ROLE = role }, fixtures, 120000)
	print_failures(report.failures)
	for _, n in ipairs(report.notes or {}) do
		print("  note " .. n)
	end
	for path, clients in pairs(report.clients or {}) do
		print(("  lsp  %s: %s"):format(path, #clients > 0 and table.concat(clients, ", ") or "-"))
	end
	local ms = startup_ms(dest)
	local base = expect.baseline_startup_ms
	if ms then
		print(
			("  time startup %.1f ms (baseline %d ms, %+.1f ms / %+.0f%%)"):format(
				ms,
				base,
				ms - base,
				(ms - base) / base * 100
			)
		)
	else
		print("  time startup unavailable")
	end
	finish(report, dest)
end

local function git_status(dir)
	local result = run({ "git", "-C", dir, "status", "--porcelain" })
	return result.code == 0 and result.stdout or nil
end

local function report_elixir(target)
	target = vim.fs.abspath(target)
	local file = target
	if vim.fn.isdirectory(target) == 1 then
		-- Pick the first module with a remote call outside comments, so go-to-definition has a target.
		file = vim.fs.find(function(name, dir)
			if not name:match("%.ex$") then
				return false
			end
			for _, line in ipairs(vim.fn.readfile(vim.fs.joinpath(dir, name))) do
				if not line:find("^%s*#") and line:find(expect.elixir_call_pattern) then
					return true
				end
			end
			return false
		end, { path = vim.fs.joinpath(target, "lib"), type = "file", limit = 1 })[1]
	end
	print(("== elixir: %s"):format(file or target))
	if not file then
		print("  FAIL [elixir] no .ex file with a remote call found under lib/")
		failed = true
		return
	end

	local project = vim.fs.root(file, "mix.exs") or vim.fs.dirname(file)
	local before = git_status(project)
	local dest = render("desktop")
	local timeout = tonumber(vim.env.SMOKE_ELIXIR_TIMEOUT or "300")
	local report = probe_run(dest, {
		SMOKE_ROLE = "desktop",
		SMOKE_MODE = "elixir",
		SMOKE_ELIXIR_FILE = file,
		SMOKE_ELIXIR_TIMEOUT = tostring(timeout),
	}, project, (timeout + 120) * 1000)
	if before and git_status(project) ~= before then
		table.insert(
			report.failures,
			{ kind = "elixir", message = "the project's git status changed during the check" }
		)
	end
	print_failures(report.failures)
	if report.elixir_server then
		print("  lsp  " .. report.elixir_server)
	end
	finish(report, dest)
end

if args.elixir then
	report_elixir(args.elixir)
else
	local roles = args.role == "all" and { "desktop", "server" } or { args.role }
	for _, role in ipairs(roles) do
		if not expect.roles[role] then
			io.stderr:write("unknown role: " .. role .. "\n")
			os.exit(2)
		end
		report_role(role)
	end
end

os.exit(failed and 1 or 0)
