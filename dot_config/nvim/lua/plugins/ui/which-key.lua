local profile = require("core.profile")

return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		preset = "helix",
	},
	config = function(_, opts)
		local wk = require("which-key")
		wk.setup(opts)

		local groups = {
			{ "<leader>a", group = "harpoon" },
			{
				"<leader>?",
				function()
					wk.show({ global = false })
				end,
				desc = "buffer local keymaps (which-key)",
			},
			{ "<leader>b", group = "buffer" },
			{ "<leader>c", group = "code" },
			{ "<leader>f", group = "find" },
			{ "<leader>g", group = "git" },
			{ "<leader>n", group = "noice" },
			{ "<leader>o", group = "opencode" },
			{ "<leader>t", group = "tabs" },
			{ "<leader>e", desc = "Explorer" },
		}

		if profile.enabled("dadbod") then
			table.insert(groups, { "<leader>d", group = "database" })
		end
		if profile.enabled("rest") then
			table.insert(groups, { "<leader>r", group = "rest" })
		end
		if profile.enabled("obsidian") then
			table.insert(groups, { "<leader>z", group = "zettelkasten" })
		end

		wk.add(groups)
	end,
}
