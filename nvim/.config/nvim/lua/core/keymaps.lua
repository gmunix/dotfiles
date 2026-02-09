local map = vim.keymap.set

map("n", "<C-h>", "<C-w>h", { desc = "Move to left window", silent = true })
map("n", "<C-j>", "<C-w>j", { desc = "Move to lower window", silent = true })
map("n", "<C-k>", "<C-w>k", { desc = "Move to upper window", silent = true })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window", silent = true })

map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer", silent = true })
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer", silent = true })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer", silent = true })
map("n", "<leader>nd", "<cmd>NoiceDismiss<CR>", { desc = "Dismiss notifications", silent = true })
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line diagnostics" })
