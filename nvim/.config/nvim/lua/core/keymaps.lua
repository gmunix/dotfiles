local map = vim.keymap.set

local function copy_to_clipboard(value, label)
	vim.fn.setreg("+", value)
	vim.fn.setreg('"', value)
	vim.notify("Copied " .. label .. ": " .. value, vim.log.levels.INFO)
end

local function copy_current_file_path()
	local path = vim.api.nvim_buf_get_name(0)
	if path == "" then
		vim.notify("No file path for current buffer", vim.log.levels.WARN)
		return
	end

	copy_to_clipboard(path, "file path")
end

local function copy_current_file_relative_path()
	local path = vim.api.nvim_buf_get_name(0)
	if path == "" then
		vim.notify("No file path for current buffer", vim.log.levels.WARN)
		return
	end

	local rel = vim.fn.fnamemodify(path, ":.")
	copy_to_clipboard(rel, "relative path")
end

map("n", "<C-h>", "<C-w>h", { desc = "Move to left window", silent = true })
map("n", "<C-j>", "<C-w>j", { desc = "Move to lower window", silent = true })
map("n", "<C-k>", "<C-w>k", { desc = "Move to upper window", silent = true })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window", silent = true })

map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer", silent = true })
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer", silent = true })
map("n", "<leader>tn", "<cmd>tabnew<CR>", { desc = "New tab", silent = true })
map("n", "<leader>tc", "<cmd>tabclose<CR>", { desc = "Close tab", silent = true })
map("n", "<leader>fp", copy_current_file_path, { desc = "Copy file path", silent = true })
map("n", "<leader>fP", copy_current_file_relative_path, { desc = "Copy relative path", silent = true })
map("n", "<leader>nd", "<cmd>NoiceDismiss<CR>", { desc = "Dismiss notifications", silent = true })
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line diagnostics" })
