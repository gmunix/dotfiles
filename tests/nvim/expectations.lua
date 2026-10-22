-- Expectations for the Neovim smoke test.
-- Later tickets update this file as the config changes; the probe and runner stay generic.

local base_plugins = {
	"lazy.nvim",
	"mini.nvim",
	"oil.nvim",
	"gitsigns.nvim",
	"which-key.nvim",
	"conform.nvim",
	"chezmoi.vim",
}

local desktop_plugins = vim.list_extend(vim.deepcopy(base_plugins), {
	"nvim-lspconfig",
	"mason.nvim",
	"nvim-treesitter",
	"nvim-ts-autotag",
	"lualine.nvim",
	"indent-blankline.nvim",
	"noice.nvim",
	"nvim-notify",
	"tiny-inline-diagnostic.nvim",
	"render-markdown.nvim",
	"monokai-nightasty.nvim",
})

local removed_plugins = {
	"telescope.nvim",
	"telescope-ui-select.nvim",
	"harpoon",
	"obsidian.nvim",
	"rest.nvim",
	"neogit",
	"codediff.nvim",
	"neotest",
	"neotest-elixir",
	"neotest-jest",
	"neotest-python",
	"nvim-nio",
	"windsurf.nvim",
	"opencode.nvim",
	"presence.nvim",
	"milli.nvim",
	"undo-glow.nvim",
	"neoscroll.nvim",
	"elixir-tools.nvim",
	"nvim-cmp",
	"cmp-nvim-lsp",
	"cmp-buffer",
	"cmp-path",
	"LuaSnip",
	"cmp_luasnip",
}

local required_keymaps = {
	n = {
		"<leader>ff",
		"<leader>fg",
		"<leader>fb",
		"<leader>fF",
		"<leader>fG",
		"<leader>fp",
		"<leader>fP",
		"<leader>e",
		"<leader>bd",
		"<leader>bD",
		"<leader>cf",
		"<leader>cd",
		"<leader>tn",
		"<leader>tc",
		"<C-h>",
		"<C-j>",
		"<C-k>",
		"<C-l>",
		"<S-h>",
		"<S-l>",
	},
}

-- Custom (non-builtin) mappings that must not exist. Built-in defaults with the same lhs are fine.
local forbidden_keymaps = {
	n = {
		"u",
		"U",
		"p",
		"P",
		"n",
		"N",
		"*",
		"#",
		"gc",
		"gcc",
		"gr",
		"<leader>rn",
		"<leader>ca",
		"<leader>eo",
		"<leader>tt",
		"<leader>tf",
		"<leader>ta",
		"<leader>ts",
		"<leader>to",
		"<leader>tO",
		"<leader>tS",
	},
	x = { "gc" },
	o = { "gc" },
}

-- Custom buffer-local mappings that must not exist in buffers with a language server attached.
local forbidden_buffer_keymaps = { n = { "gr", "<leader>rn", "<leader>ca" } }

-- Any custom mapping starting with one of these prefixes is forbidden.
local forbidden_prefixes = {
	n = { "<leader>a", "<leader>o", "<leader>r", "<leader>z" },
}

-- Fixture file -> language servers. `servers` must attach when their binary is installed;
-- `forbidden_servers` must never attach.
local files = {
	{ path = "sample.lua", servers = { lua_ls = "lua-language-server" } },
	{
		path = "sample.md",
		servers = { marksman = "marksman" },
		forbidden_servers = { "obsidian-ls", "tailwindcss" },
	},
	{ path = "sample.ts", servers = { vtsls = "vtsls" } },
	{ path = "sample.vue" },
	{ path = "sample.ex" },
	{ path = "sample.heex" },
}

return {
	-- Best-of-two warm headless startup of the pre-simplification config, measured with this harness.
	baseline_startup_ms = 91,
	files = files,
	removed_plugins = removed_plugins,
	required_keymaps = required_keymaps,
	forbidden_keymaps = forbidden_keymaps,
	forbidden_buffer_keymaps = forbidden_buffer_keymaps,
	forbidden_prefixes = forbidden_prefixes,
	-- Lua patterns that mark a message or stderr line as an error or warning.
	error_patterns = { "E%d+:", "[Ee]rror", "[Ww]arn", "deprecated", "attempt to ", "callback: " },
	-- Keys that open a picker; the probe opens each one, lets the preview render, then closes it.
	picker_keys = { "<leader>ff" },
	-- Language servers accepted for the optional Elixir project check.
	elixir_servers = { "expert", "elixirls", "ElixirLS" },
	-- A qualified remote call such as `Enum.map(`; the capture is the function name used for go-to-definition.
	elixir_call_pattern = "[A-Z][%w_]*%.[%w_.]*%.?([a-z_][%w_]*[?!]?)%(",
	roles = {
		desktop = { required_plugins = desktop_plugins },
		-- Server-role behaviour is defined in the machine-role profiles ticket; until then it matches desktop.
		server = { required_plugins = desktop_plugins },
	},
}
