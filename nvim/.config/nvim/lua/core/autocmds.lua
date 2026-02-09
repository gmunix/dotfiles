local checktime_group = vim.api.nvim_create_augroup("core_checktime", { clear = true })

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
	group = checktime_group,
	command = "checktime",
})
