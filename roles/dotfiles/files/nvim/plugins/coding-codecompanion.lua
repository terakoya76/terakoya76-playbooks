return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("codecompanion").setup({
      adapters = {
        ollama = function()
          return require("codecompanion.adapters").extend("ollama", {
            schema = {
              model = {
                default = "qwen2.5-coder:14b",
              },
            },
          })
        end,
      },
      strategies = {
        chat = {
          adapter = "ollama",
        },
        inline = {
          adapter = "ollama",
        },
        agent = {
          adapter = "ollama",
        },
      },
    })

    local opts = { noremap = true, silent = true }
    vim.keymap.set("n", "<C-a>", "<cmd>CodeCompanionActions<CR>", opts)
    vim.keymap.set("v", "<C-a>", "<cmd>CodeCompanionActions<CR>", opts)
    vim.keymap.set("n", "<LocalLeader>a", "<cmd>CodeCompanionChat Toggle<CR>", opts)
    vim.keymap.set("v", "<LocalLeader>a", "<cmd>CodeCompanionChat Toggle<CR>", opts)
    vim.keymap.set("v", "ga", "<cmd>CodeCompanionChat Add<CR>", opts)

    -- Expand 'cc' into 'CodeCompanion' in the command line
    vim.cmd([[cab cc CodeCompanion]])
    vim.cmd([[cab ccc CodeCompanionChat]])
  end,
}
