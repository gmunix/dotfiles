local checktime_group = vim.api.nvim_create_augroup("core_checktime", { clear = true })

local function checktime_all_buffers()
	if vim.fn.mode() == "c" then
		return
	end

	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf)
			and vim.bo[buf].buftype == ""
			and vim.api.nvim_buf_get_name(buf) ~= ""
			and not vim.bo[buf].modified
		then
			pcall(vim.cmd, ("silent! checktime %d"):format(buf))
		end
	end
end

vim.api.nvim_create_autocmd(
	{ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI", "TermClose", "TermLeave" },
	{
		group = checktime_group,
		callback = checktime_all_buffers,
	}
)

vim.api.nvim_create_autocmd("FileChangedShellPost", {
	group = checktime_group,
	callback = function(event)
		local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(event.buf), ":~:.")
		vim.notify(("Reloaded changed file: %s"):format(filename), vim.log.levels.INFO, { title = "checktime" })
	end,
})
