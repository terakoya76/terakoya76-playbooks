vim.cmd("autocmd!")
vim.cmd("syntax on")

vim.scriptencoding = "utf-8"

vim.wo.number = true

-- Open hoge file
vim.api.nvim_create_user_command("Memo", function(opts)
	vim.cmd("e " .. "~/_/memo/memo.markdown")
end, {})

-- need to start outside of plugin def
require('lualine').setup()
