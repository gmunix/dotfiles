return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
	config = function()
		local harpoon = require("harpoon")

		harpoon:setup()

		vim.keymap.set("n", "<leader>aa", function()
			harpoon:list():add()
		end, { desc = "Add file to Harpoon" })

		vim.keymap.set("n", "<leader>am", function()
			harpoon.ui:toggle_quick_menu(harpoon:list())
		end, { desc = "Toggle Harpoon quick menu" })

		vim.keymap.set("n", "<leader>ah", function()
			harpoon:list():select(1)
		end, { desc = "Select harpoon file 1" })
		vim.keymap.set("n", "<leader>aj", function()
			harpoon:list():select(2)
		end, { desc = "Select harpoon file 2" })
		vim.keymap.set("n", "<leader>ak", function()
			harpoon:list():select(3)
		end, { desc = "Select harpoon file 3" })
		vim.keymap.set("n", "<leader>al", function()
			harpoon:list():select(4)
		end, { desc = "Select harpoon file 4" })
		vim.keymap.set("n", "<leader>ap", function()
			harpoon:list():prev()
		end, { desc = "Harpoon previous file" })
		vim.keymap.set("n", "<leader>an", function()
			harpoon:list():next()
		end, { desc = "Harpoon next file" })

		local conf = require("telescope.config").values
		local function toggle_telescope(harpoon_files)
			local file_paths = {}
			local items = harpoon_files.items
			local keys = {}
			for k in pairs(items) do
				keys[#keys + 1] = k
			end
			table.sort(keys)
			for _, k in ipairs(keys) do
				table.insert(file_paths, items[k].value)
			end

			require("telescope.pickers")
				.new({}, {
					prompt_title = "Harpoon",
					finder = require("telescope.finders").new_table({
						results = file_paths,
					}),
					previewer = conf.file_previewer({}),
					sorter = conf.generic_sorter({}),
				})
				:find()
		end

		vim.keymap.set("n", "<leader>as", function()
			toggle_telescope(harpoon:list())
		end, { desc = "Open harpoon window" })
	end,
}
