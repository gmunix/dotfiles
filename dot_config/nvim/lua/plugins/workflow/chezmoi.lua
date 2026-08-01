return {
	"alker0/chezmoi.vim",
	lazy = false,
	init = function()
		vim.g["chezmoi#use_external"] = "chezmoi"
		vim.g["chezmoi#use_tmp_buffer"] = true
	end,
}
