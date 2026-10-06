-- The frozen master branch passes nodes to query directives in the pre-0.11 shape,
-- which breaks the highlighter on Neovim 0.12 ("attempt to call method 'range'").
-- main requires tree-sitter-cli >= 0.26.1 (installed via mise) and does not support lazy-loading.
return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  lazy = false,
  build = ':TSUpdate',
  config = function()
    require('nvim-treesitter').install({ 'python', 'typescript' })

    -- main no longer enables highlighting itself; pcall skips filetypes without a parser
    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('treesitter-highlight', { clear = true }),
      callback = function(args)
        pcall(vim.treesitter.start, args.buf)
      end,
    })
  end,
}
