local tooling = require("core.tooling")

local M = {}

local health = vim.health

local function report(kind, message)
	local fn = health[kind] or health["report_" .. kind]
	if fn then
		fn(message)
	end
end

local function start(message)
	report("start", message)
end

local function python_venv_available()
	if not tooling.has_python() then
		return false
	end

	vim.fn.system({ "python3", "-c", "import venv" })
	return vim.v.shell_error == 0
end

function M.missing_critical()
	local labels = {}
	for _, dependency in ipairs(tooling.missing(tooling.critical_dependencies)) do
		table.insert(labels, dependency.label)
	end

	return labels
end

function M.check()
	start("Required OS tools")
	for _, dependency in ipairs(tooling.critical_dependencies) do
		if tooling.has_any(dependency.commands) then
			report("ok", dependency.label)
		else
			report("error", dependency.label .. " missing. " .. dependency.hint)
		end
	end

	start("Recommended language runtimes")
	if tooling.has_node() then
		report("ok", "node and npm available")
	else
		report("warn", "node/npm missing. Node-based LSPs and formatters will not auto-install.")
	end

	if tooling.has_python() then
		report("ok", "python3 available")
	else
		report("warn", "python3 missing. Python formatters will not auto-install.")
	end

	if python_venv_available() then
		report("ok", "python3 venv module available")
	else
		report("warn", "python3 venv module missing. Mason Python package installs can fail on some Linux distros.")
	end

	if tooling.has_elixir() then
		report("ok", "elixir and mix available")
	else
		report("warn", "elixir/mix missing. ElixirLS will not auto-install and Elixir tooling may be limited.")
	end

	if tooling.has_compiler() then
		report("ok", "C compiler and make available")
	else
		report("warn", "C compiler or make missing. Treesitter parser auto-install is disabled.")
	end

	start("Neovim config")
	report("info", "Mason LSP installs: " .. table.concat(tooling.mason_lsp_servers(), ", "))
	report("info", "Mason tool installs: " .. table.concat(tooling.mason_tools(), ", "))
	report("info", "Run scripts/nvim-deps.sh --install to install common OS dependencies.")
end

function M.register()
	pcall(vim.api.nvim_create_user_command, "DotfilesHealth", function()
		vim.cmd("checkhealth dotfiles")
	end, { desc = "Run dotfiles Neovim health checks" })

	local group = vim.api.nvim_create_augroup("dotfiles_health", { clear = true })
	vim.api.nvim_create_autocmd("VimEnter", {
		group = group,
		once = true,
		callback = function()
			local missing = M.missing_critical()
			if #missing == 0 then
				return
			end

			vim.notify(
				"Missing Neovim dependencies: " .. table.concat(missing, ", ") .. ". Run :DotfilesHealth.",
				vim.log.levels.WARN,
				{ title = "dotfiles" }
			)
		end,
	})
end

return M
