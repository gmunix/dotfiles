local M = {}

-- Shared ripgrep globs used by Telescope's opt-in "search ignored files" bindings.
-- Keep this focused on generated artifacts, dependency dirs, and caches.
M.rg_globs = {
	-- VCS and JS/TS artifacts
	"!**/.git/**",
	"!**/node_modules/**",
	"!**/.next/**",
	"!**/.nuxt/**",
	"!**/.turbo/**",
	"!**/.vite/**",
	"!**/.yarn/**",
	"!**/.pnpm-store/**",
	"!**/.parcel-cache/**",
	"!**/.vercel/**",
	"!**/coverage/**",
	"!**/dist/**",
	"!**/build/**",
	-- Elixir
	"!**/_build/**",
	"!**/deps/**",
	"!**/.elixir_ls/**",
	-- Python
	"!**/__pycache__/**",
	"!**/.pytest_cache/**",
	"!**/.mypy_cache/**",
	"!**/.ruff_cache/**",
	"!**/.tox/**",
	"!**/.venv/**",
	"!**/venv/**",
	"!**/*.pyc",
	-- Java/JVM
	"!**/.gradle/**",
	"!**/target/**",
	"!**/out/**",
	"!**/*.class",
	-- Go and generic caches
	"!**/vendor/**",
	"!**/.cache/**",
	"!**/tmp/**",
}

local function with_globs(args)
	local result = vim.deepcopy(args)
	for _, glob in ipairs(M.rg_globs) do
		vim.list_extend(result, { "--glob", glob })
	end
	return result
end

function M.rg_find_files_command()
	return with_globs({ "rg", "--files", "--hidden", "--no-ignore-vcs" })
end

function M.rg_additional_args()
	return with_globs({ "--hidden", "--no-ignore-vcs" })
end

return M
