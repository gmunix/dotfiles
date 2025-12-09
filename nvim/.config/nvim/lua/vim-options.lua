-- Set leader keymap
vim.g.mapleader = " "

-- Set tabs to be 2 spaces
vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.cmd("set number")
vim.cmd("set relativenumber")

-- Configure system clipboard
vim.opt.clipboard = "unnamedplus"

-- Configure window move keybindings
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")

-- Configure Keymaps for Buffers
vim.keymap.set("n", "<S-h>", ":bprevious<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "<S-l>", ":bnext<CR>", { desc = "Next buffer" })

vim.keymap.set("n", "<leader>bd", ":bdelete<CR>", { desc = "Delete buffer" })

-- Configure Keymaps for Noice
vim.keymap.set("n", "<leader>nd", ":NoiceDismiss<CR>", { desc = "Dismiss notifications" })

-- Configure Keymaps for Diagnostics
vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line diagnostics" })

-- Auto-reload files changed outside of Neovim
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
	command = "checktime",
})

-- Make CursorHold trigger faster
vim.opt.updatetime = 1000
