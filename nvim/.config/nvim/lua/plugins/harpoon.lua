return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
	config = function()
		local harpoon = require("harpoon")

		-- REQUIRED
		harpoon:setup()
		-- REQUIRED

		vim.keymap.set("n", "<leader>aa", function()
			harpoon:list():add()
		end)

		vim.keymap.set("n", "<C-e>", function()
			harpoon.ui:toggle_quick_menu(harpoon:list())
		end)

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

		-- Toggle previous & next buffers stored within Harpoon list
		vim.keymap.set("n", "<C-S-P>", function()
			harpoon:list():prev()
		end)
		vim.keymap.set("n", "<C-S-N>", function()
			harpoon:list():next()
		end)

		-- basic telescope configuration
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
