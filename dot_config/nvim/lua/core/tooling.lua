local M = {}

M.critical_dependencies = {
	{ label = "git", commands = { "git" }, hint = "Required by lazy.nvim and Mason downloads." },
	{ label = "curl or wget", commands = { "curl", "wget" }, hint = "Required to download Mason packages." },
	{ label = "unzip", commands = { "unzip" }, hint = "Required to unpack Mason packages." },
	{ label = "tar or gtar", commands = { "tar", "gtar" }, hint = "Required to unpack Mason packages." },
	{ label = "gzip", commands = { "gzip" }, hint = "Required to unpack Mason packages." },
	{ label = "ripgrep", commands = { "rg" }, hint = "Required by Telescope search mappings." },
}

M.treesitter_parsers = {
	"bash",
	"css",
	"elixir",
	"eex",
	"heex",
	"html",
	"http",
	"javascript",
	"json",
	"lua",
	"markdown",
	"markdown_inline",
	"python",
	"query",
	"tsx",
	"typescript",
	"vim",
	"vimdoc",
	"yaml",
}

local core_lsp_servers = {
	"lua_ls",
	"marksman",
	"taplo",
}

local node_lsp_servers = {
	"bashls",
	"cssls",
	"docker_compose_language_service",
	"dockerls",
	"emmet_ls",
	"eslint",
	"html",
	"jsonls",
	"pyright",
	"tailwindcss",
	"vtsls",
	"yamlls",
}

local node_tools = {
	"prettier",
	"prettierd",
	"eslint_d",
}

local python_tools = {
	"black",
	"isort",
}

function M.has(command)
	return vim.fn.executable(command) == 1
end

function M.has_any(commands)
	for _, command in ipairs(commands) do
		if M.has(command) then
			return true
		end
	end

	return false
end

function M.has_node()
	return M.has("node") and M.has("npm")
end

function M.has_python()
	return M.has("python3")
end

function M.has_elixir()
	return M.has("elixir") and M.has("mix")
end

function M.has_compiler()
	return M.has_any({ "cc", "gcc", "clang" }) and M.has_any({ "make", "gmake" })
end

function M.has_tree_sitter_cli()
	return M.has("tree-sitter")
end

function M.can_install_treesitter_parsers()
	return M.has_compiler() and M.has_tree_sitter_cli()
end

function M.missing(dependencies)
	local missing = {}
	for _, dependency in ipairs(dependencies) do
		if not M.has_any(dependency.commands) then
			table.insert(missing, dependency)
		end
	end

	return missing
end

function M.mason_lsp_servers()
	local servers = vim.deepcopy(core_lsp_servers)

	if M.has_node() then
		vim.list_extend(servers, node_lsp_servers)
	end
	if M.has_elixir() then
		table.insert(servers, "elixirls")
	end

	return servers
end

function M.enabled_lsp_servers()
	local enabled = {}
	for _, server in ipairs(M.mason_lsp_servers()) do
		enabled[server] = true
	end

	return enabled
end

function M.mason_tools()
	local tools = { "stylua" }

	if M.has_node() then
		vim.list_extend(tools, node_tools)
	end
	if M.has_python() then
		vim.list_extend(tools, python_tools)
	end

	return tools
end

function M.treesitter_ensure_installed()
	if not M.can_install_treesitter_parsers() then
		return {}
	end

	return vim.deepcopy(M.treesitter_parsers)
end

return M
