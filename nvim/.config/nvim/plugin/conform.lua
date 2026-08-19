vim.pack.add({
  "https://github.com/williamboman/mason.nvim",
  "https://github.com/stevearc/conform.nvim",
  "https://github.com/zapling/mason-conform.nvim",
  "https://github.com/folke/snacks.nvim",
})

require("mason").setup()

require("conform").setup({
  format_on_save = function()
    if vim.g.disable_autoformat then return end
    return { timeout_ms = 1000, lsp_format = "fallback" }
  end,
  formatters_by_ft = {
    bash = { "shfmt" },
    json = { "prettier" },
    jsonc = { "prettier" },
    lua = { "stylua" },
    markdown = { "prettier" },
    python = { "black" },
    sh = { "shfmt" },
    yaml = { "prettier" },
    zsh = { "shfmt" },
  },
})

require("mason-conform").setup()

vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

vim.keymap.set({ "n", "v" }, "<leader>cf", function() require("conform").format({ async = true, lsp_format = "fallback" }) end, { desc = "Format" })

require("snacks").toggle
  .new({
    name = "Format on Save",
    get = function() return not vim.g.disable_autoformat end,
    set = function(state) vim.g.disable_autoformat = not state end,
  })
  :map("<leader>uf")
