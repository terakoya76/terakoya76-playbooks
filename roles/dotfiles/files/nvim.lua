-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- load ~/.config/nvim/lua/plugins/*.lua
    { { import = "plugins" } }
  },
  -- automatically check for plugin updates
  checker = { enabled = true },
})

require("base")
require("autocmds")
require("options")
require("keymaps")

require("everforest").load()

-- for python3 provider
vim.g.python3_host_prog = '/usr/bin/python3'
-- for ruby provider
vim.g.ruby_host_prog = '$HOME/.anyenv/envs/rbenv/versions/3.0.1/bin/neovim-ruby-host'
