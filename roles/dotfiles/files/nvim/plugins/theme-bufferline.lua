return {
  'akinsho/bufferline.nvim',
  version = "*",
  dependencies = 'nvim-tree/nvim-web-devicons',
  config = function ()
    vim.opt.termguicolors = true
    require("bufferline").setup{}

    local opts = { noremap = true, silent = true }
    vim.keymap.set("n", '<Leader>hh', ':bprev<CR>', opts)
    vim.keymap.set("n", '<Leader>ll', ':bnext<CR>',  opts)
  end
}
