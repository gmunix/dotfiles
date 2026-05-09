local profile = require("core.profile")

return {
	"obsidian-nvim/obsidian.nvim",
	cond = function()
		return profile.enabled("obsidian")
	end,
	version = "*",
	ft = { "markdown" },
	cmd = "Obsidian",
	keys = {
		{
			"<leader>zf",
			function()
				vim.cmd("Obsidian quick_switch")
			end,
			desc = "Find notes",
		},
		{
			"<leader>zs",
			function()
				vim.cmd("Obsidian search")
			end,
			desc = "Search notes",
		},
		{
			"<leader>zn",
			function()
				vim.cmd("Obsidian new")
			end,
			desc = "New note",
		},
		{
			"<leader>zN",
			function()
				vim.cmd("Obsidian new_from_template")
			end,
			desc = "New note from template",
		},
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim",
	},
	config = function()
		local api = require("obsidian.api")

		require("obsidian").setup({
			legacy_commands = false,
			workspaces = {
				{
					name = "zettelkasten",
					path = "~/Notes/zettelkasten",
				},
			},
			notes_subdir = "Zettelkasten/6 - Zettelkasten",
			new_notes_location = "notes_subdir",
			link = {
				style = "wiki",
			},
			note_id_func = function(title)
				if title == nil or title == "" then
					return tostring(os.time())
				end

				return title:gsub("/", "-"):gsub("\\", "-"):gsub(":", " -")
			end,
			frontmatter = {
				enabled = false,
			},
			note = {
				template = "Full Note.md",
			},
			completion = {
				nvim_cmp = true,
				min_chars = 2,
				create_new = true,
			},
			picker = {
				name = "telescope.nvim",
				note_mappings = {
					new = "<C-x>",
					insert_link = "<C-l>",
				},
				tag_mappings = {
					tag_note = "<C-x>",
					insert_tag = "<C-l>",
				},
			},
			templates = {
				folder = "Zettelkasten/5 - Templates",
				date_format = "%Y-%m-%d",
				time_format = "%H:%M",
				substitutions = {
					Title = function(ctx)
						return ctx.partial_note and ctx.partial_note:display_name() or nil
					end,
				},
			},
			attachments = {
				folder = "Zettelkasten/8 - Images",
				img_name_func = function()
					return string.format("Pasted image %s", os.date("%Y%m%d%H%M%S"))
				end,
				img_text_func = function(path)
					local name = vim.fs.basename(tostring(path))

					if Obsidian.opts.link.style == "wiki" then
						return string.format("![[%s]]", name)
					end

					return string.format("![%s](%s)", name, require("obsidian.util").urlencode(name))
				end,
			},
			ui = {
				enable = false,
			},
			callbacks = {
				enter_note = function(note)
					local map = function(lhs, rhs, desc, opts)
						opts = opts or {}
						opts.buffer = note.bufnr
						opts.desc = desc
						vim.keymap.set("n", lhs, rhs, opts)
					end

					map("gf", function()
						api.follow_link()
					end, "Follow link")
					map("<CR>", function()
						return api.smart_action() or "<CR>"
					end, "Smart action", { expr = true })
					map("<leader>zc", function()
						api.toggle_checkbox()
					end, "Toggle checkbox")
				end,
			},
		})
	end,
}
