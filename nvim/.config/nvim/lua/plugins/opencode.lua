return {
	"nickjvandyke/opencode.nvim",
	version = "*",
	config = function()
		vim.g.opencode_opts = {}
		vim.o.autoread = true

		local opencode = require("opencode")

		vim.keymap.set({ "n", "x" }, "<leader>oa", function()
			opencode.ask("@this: ", { submit = true })
		end, { desc = "Ask opencode" })

		vim.keymap.set("n", "<leader>oo", function()
			opencode.toggle()
		end, { desc = "Toggle opencode" })

		vim.keymap.set({ "n", "x" }, "<leader>os", function()
			opencode.select()
		end, { desc = "Select opencode action" })
	end,
}
